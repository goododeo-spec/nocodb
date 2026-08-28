import assert from 'node:assert/strict';
import { describe, it } from 'node:test';
import {
  readCdnSignerConfigFromEnv,
  signPreviewCdnUrl,
  shouldUseCdnPreview,
} from './cdnUrlSigner.ts';

describe('cdnUrlSigner', () => {
  const config = {
    cdnBaseUrl: 'https://video.example.com/',
    authKey: 'secret',
    ttlSeconds: 600,
    type: 'aliyun-a' as const,
  };

  it('falls back to the original S3 path when CDN is not configured', () => {
    assert.equal(
      signPreviewCdnUrl({ cdnBaseUrl: '', authKey: '' }, { objectKey: 'a.mp4', preview: true }),
      null,
    );
    assert.equal(shouldUseCdnPreview({ cdnBaseUrl: 'https://cdn.example', authKey: '' }, true), false);
  });

  it('only signs inline preview requests', () => {
    assert.equal(
      signPreviewCdnUrl(config, { objectKey: 'nc/uploads/clip.mp4', preview: false }),
      null,
    );
  });

  it('signs an Aliyun type-A preview URL without leaking the raw key', () => {
    const url = signPreviewCdnUrl(config, {
      objectKey: 'nc/uploads/你好 clip.mp4?foo=1',
      preview: true,
      nowMs: 1_700_000_000_000,
    });
    assert.ok(url);
    assert.match(url!, /^https:\/\/video\.example\.com\/nc\/uploads\/你好 clip\.mp4\?auth_key=/);
    assert.doesNotMatch(url!, /secret/);
    assert.doesNotMatch(url!, /foo=1/);
  });

  it('rejects expired tokens by advancing the clock past ttl', () => {
    const nowMs = 1_700_000_000_000;
    const url = signPreviewCdnUrl(config, {
      objectKey: 'nc/uploads/clip.mp4',
      preview: true,
      nowMs,
    })!;
    const timestamp = Number(new URL(url).searchParams.get('auth_key')!.split('-')[0]);
    assert.equal(timestamp, Math.floor(nowMs / 1000) + 600);
    assert.ok(timestamp < Math.floor(nowMs / 1000) + 601);
    assert.ok(timestamp <= Math.floor(nowMs / 1000) + 600);
  });

  it('reads env config without enabling when type is off', () => {
    const envConfig = readCdnSignerConfigFromEnv({
      NC_CDN_BASE_URL: 'https://cdn.example',
      NC_CDN_AUTH_KEY: 'secret',
      NC_CDN_AUTH_TYPE: 'off',
    });
    assert.equal(shouldUseCdnPreview(envConfig, true), false);
  });
});
