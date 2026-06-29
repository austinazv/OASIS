/**
 * Import function triggers from their respective submodules:
 *
 * import {onCall} from "firebase-functions/v2/https";
 * import {onDocumentWritten} from "firebase-functions/v2/firestore";
 *
 * See a full list of supported triggers at https://firebase.google.com/docs/functions
 */

import {setGlobalOptions} from "firebase-functions";
import {onRequest} from "firebase-functions/https";
import {defineSecret} from "firebase-functions/params";

const spotifyClientId = defineSecret("SPOTIFY_CLIENT_ID");
const spotifyClientSecret = defineSecret("SPOTIFY_CLIENT_SECRET");
const spotifyRefreshToken = defineSecret("SPOTIFY_REFRESH_TOKEN");
// import * as logger from "firebase-functions/logger";

// Start writing functions
// https://firebase.google.com/docs/functions/typescript

export const testSpotifyAuth = onRequest(
  {
    secrets: [
      spotifyClientId,
      spotifyClientSecret,
      spotifyRefreshToken,
    ],
  },
  async (req, res) => {
    try {
      const credentials = Buffer.from(
        `${spotifyClientId.value()}:${spotifyClientSecret.value()}`
      ).toString("base64");

      const response = await fetch("https://accounts.spotify.com/api/token",
        {
          method: "POST",
          headers: {
            "Authorization": `Basic ${credentials}`,
            "Content-Type": "application/x-www-form-urlencoded",
          },
          body: new URLSearchParams({
            grant_type: "refresh_token",
            refresh_token: spotifyRefreshToken.value(),
          }),
        },
      );

      const json = await response.json();

      res.json({
        success: response.ok,
        hasAccessToken: !!json.access_token,
        scope: json.scope,
      });
    } catch (error) {
      res.status(500).json({
        success: false,
        error: String(error),
      });
    }
  }
);

/**
 * Gets Spotify access token using refresh token
 */
async function getAccessToken() {
  const credentials = Buffer.from(
    `${spotifyClientId.value()}:${spotifyClientSecret.value()}`
  ).toString("base64");

  const response = await fetch("https://accounts.spotify.com/api/token", {
    method: "POST",
    headers: {
      "Authorization": `Basic ${credentials}`,
      "Content-Type": "application/x-www-form-urlencoded",
    },
    body: new URLSearchParams({
      grant_type: "refresh_token",
      refresh_token: spotifyRefreshToken.value(),
    }),
  });

  const data = await response.json();
  return data.access_token;
}

/**
 * Fetches top tracks for an artist from Spotify
 *
 * @param {string} artistID - Spotify artist ID
 * @param {string} accessToken - Spotify access token
 * @param {number} limit - Number of top tracks to fetch (default 5)
 * @return {string[]} Array of Spotify track URIs
 */
async function getArtistTopTracks(
  artistID: string,
  accessToken: string,
  limit = 5
) {
  const res = await fetch(
    `https://api.spotify.com/v1/artists/${artistID}/top-tracks?market=US`,
    {
      headers: {
        Authorization: `Bearer ${accessToken}`,
      },
    }
  );

  const data = await res.json();

  return (data.tracks || [])
    .slice(0, limit)
    .map((t: {uri: string}) => t.uri);
}

export const createSpotifyPlaylist = onRequest(
  {
    secrets: [
      spotifyClientId,
      spotifyClientSecret,
      spotifyRefreshToken,
    ],
  },
  async (req, res) => {
    try {
      const {playlistName, artistIDs} = req.body;

      if (!playlistName || !artistIDs?.length) {
        res.status(400).json({error: "Missing playlistName or artistIDs"});
        return;
      }

      const accessToken = await getAccessToken();

      // 1. Get user (Oasis account)
      const userRes = await fetch("https://api.spotify.com/v1/me", {
        headers: {Authorization: `Bearer ${accessToken}`},
      });

      const user = await userRes.json();
      const userId = user.id;

      // 2. Create playlist
      const playlistRes = await fetch(
        `https://api.spotify.com/v1/users/${userId}/playlists`,
        {
          method: "POST",
          headers: {
            "Authorization": `Bearer ${accessToken}`,
            "Content-Type": "application/json",
          },
          body: JSON.stringify({
            name: playlistName,
            public: false,
            collaborative: true,
            description: "Created using OASIS",
            // public: true,
          }),
        }
      );

      const playlist = await playlistRes.json();
      const playlistId = playlist.id;

      // 3. Gather tracks
      let allTracks: string[] = [];

      for (const artistID of artistIDs) {
        const tracks = await getArtistTopTracks(artistID, accessToken, 5);
        allTracks.push(...tracks);
      }

      // 4. Deduplicate
      allTracks = [...new Set(allTracks)];

      // 5. Add tracks in batches of 100
      for (let i = 0; i < allTracks.length; i += 100) {
        const batch = allTracks.slice(i, i + 100);

        await fetch(
          `https://api.spotify.com/v1/playlists/${playlistId}/tracks`,
          {
            method: "POST",
            headers: {
              "Authorization": `Bearer ${accessToken}`,
              "Content-Type": "application/json",
            },
            body: JSON.stringify({uris: batch}),
          }
        );
      }

      // 6. Return playlist URL
      res.json({
        success: true,
        playlistUrl: playlist.external_urls.spotify,
        trackCount: allTracks.length,
      });
    } catch (error) {
      res.status(500).json({
        success: false,
        error: String(error),
      });
    }
  }
);

// For cost control, you can set the maximum number of containers that can be
// running at the same time. This helps mitigate the impact of unexpected
// traffic spikes by instead downgrading performance. This limit is a
// per-function limit. You can override the limit for each function using the
// `maxInstances` option in the function's options, e.g.
// `onRequest({ maxInstances: 5 }, (req, res) => { ... })`.
// NOTE: setGlobalOptions does not apply to functions using the v1 API. V1
// functions should each use functions.runWith({ maxInstances: 10 }) instead.
// In the v1 API, each function can only serve one request per container, so
// this will be the maximum concurrent request count.
setGlobalOptions({maxInstances: 10});

// export const helloWorld = onRequest((request, response) => {
//   logger.info("Hello logs!", {structuredData: true});
//   response.send("Hello from Firebase!");
// });
