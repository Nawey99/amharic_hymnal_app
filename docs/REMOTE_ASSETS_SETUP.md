# Remote Assets Setup Guide

## Overview

The app now uses remote CDN/server for sheet music and audio files instead of bundling them in the APK. This reduces initial app size from ~1.8GB to <100MB.

## Sheet Music Setup

### URL Patterns

The app expects sheet music files to be accessible via the following URL patterns:

**Single Page Format:**
```
{baseUrl}/sheet_music/{hymnNumber}.webp
```

**Two Page Format:**
```
{baseUrl}/sheet_music/{hymnNumber}_L.webp
{baseUrl}/sheet_music/{hymnNumber}_R.webp
```

### Examples

- Hymn 1 (single page): `https://cdn.example.com/sheet_music/1.webp`
- Hymn 8 (two pages): 
  - `https://cdn.example.com/sheet_music/8_L.webp`
  - `https://cdn.example.com/sheet_music/8_R.webp`

### File Requirements

- **Format**: WebP only (`.webp` extension)
- **Resolution**: Maximum 2000px width recommended
- **Compression**: Optimize for web (quality 80-85)
- **Naming**: Use hymn number as filename (e.g., `1.webp`, `8_L.webp`)

## Audio Setup

Audio files are already configured to use remote URLs via `GlobalAudioService`.

### URL Pattern
```
{baseUrl}/audio/{hymnNumber}?apiKey={apiKey}
```

Or via API response:
```
GET {baseUrl}/api/audio/{hymnNumber}
Response: { "url": "https://..." }
```

## Configuration

### Initialize Services

In your app initialization (e.g., `main.dart`):

```dart
// Initialize remote sheet music service
await RemoteSheetMusicService().initialize(
  baseUrl: 'https://cdn.example.com',
  apiKey: 'your-api-key', // Optional
);

// Initialize audio service (if not already done)
await GlobalAudioService().initialize(
  baseUrl: 'https://api.example.com',
  apiKey: 'your-api-key', // Optional
);
```

### Environment-Based URLs

You can use different URLs for development, staging, and production:

```dart
final baseUrl = kDebugMode 
  ? 'https://dev-cdn.example.com'
  : 'https://cdn.example.com';
```

## CDN/Server Setup Options

### Option 1: Static File Hosting (Recommended)

Use a CDN or object storage service:
- **AWS S3 + CloudFront**
- **Google Cloud Storage + CDN**
- **Azure Blob Storage + CDN**
- **Cloudflare R2**
- **GitHub Pages** (for public assets)

### Option 2: API Server

Create an API endpoint that returns file URLs:
```
GET /api/sheet_music/{hymnNumber}
Response: { "urls": ["url1", "url2"] }
```

### Option 3: Hybrid

Store files on CDN, use API for metadata/availability checks.

## File Migration

### Moving Sheet Music Files

1. Upload all 398 `.webp` files from `assets/sheet_music/` to your CDN
2. Ensure files are accessible via HTTP/HTTPS
3. Verify URL patterns match expected format
4. Test with a few hymn numbers

### Recommended CDN Structure

```
cdn-root/
  sheet_music/
    1.webp
    2.webp
    3.webp
    ...
    8_L.webp
    8_R.webp
    ...
```

## Testing

### Test Remote Loading

1. Set base URL in app initialization
2. Open a hymn with sheet music
3. Verify image loads from remote URL
4. Check cache directory for downloaded files

### Test Offline Mode

1. Download sheet music for a hymn
2. Disable network connection
3. Open the same hymn
4. Verify cached file loads correctly

## Cache Management

Users can manage cache in Settings:
- View current cache size
- Clear all cached files
- Files are automatically downloaded when viewed

Cache location: `{app_documents}/sheet_music_cache/`

## Troubleshooting

### Images Not Loading

1. Check base URL is correctly configured
2. Verify files exist at expected URLs
3. Check network connectivity
4. Review error logs in debug mode

### Cache Issues

1. Clear app cache in Settings
2. Check available storage space
3. Verify cache directory permissions

## Security Considerations

- Use HTTPS for all remote URLs
- Implement API key authentication if needed
- Consider rate limiting for API endpoints
- Validate file types server-side

## Performance Tips

- Enable CDN caching headers
- Use WebP format for optimal compression
- Implement progressive loading (thumbnails → full resolution)
- Consider lazy loading for large collections





