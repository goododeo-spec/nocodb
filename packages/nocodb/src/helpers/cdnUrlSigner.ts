import { createHash } from 'crypto';

export type CdnSignerConfig = {
  cdnBaseUrl?: string;
  authKey?: string;
  ttlSeconds?: number;
  type?: 'aliyun-a' | 'off';
};

export type SignCdnUrlInput = {
  objectKey: string;
  preview: boolean;
  nowMs?: number;
};

const DEFAULT_TTL_SECONDS = 10 * 60;

export function normalizeCdnBaseUrl(cdnBaseUrl?: string): string | null {
  if (!cdnBaseUrl) return null;
  return cdnBaseUrl.replace(/\/+$/, '');
}

export function sanitizeObjectKey(objectKey: string): string {
  return objectKey.replace(/^\/+/, '').split('?')[0].split('#')[0];
}

export function shouldUseCdnPreview(config: CdnSignerConfig, preview: boolean): boolean {
  return (
    preview &&
    config.type !== 'off' &&
    Boolean(normalizeCdnBaseUrl(config.cdnBaseUrl) && config.authKey)
  );
}

/**
 * Aliyun CDN URL auth type A:
 * auth_key = timestamp-rand-uid-md5(uri-timestamp-rand-uid-key)
 */
export function signAliyunTypeA(
  cdnBaseUrl: string,
  objectKey: string,
  authKey: string,
  ttlSeconds = DEFAULT_TTL_SECONDS,
  nowMs = Date.now(),
  rand = '0',
): string {
  const base = normalizeCdnBaseUrl(cdnBaseUrl);
  const key = sanitizeObjectKey(objectKey);
  const uri = `/${key}`;
  const timestamp = Math.floor(nowMs / 1000) + ttlSeconds;
  const uid = '0';
  const md5 = createHash('md5')
    .update(`${uri}-${timestamp}-${rand}-${uid}-${authKey}`)
    .digest('hex');
  return `${base}${uri}?auth_key=${timestamp}-${rand}-${uid}-${md5}`;
}

export function signPreviewCdnUrl(
  config: CdnSignerConfig,
  input: SignCdnUrlInput,
): string | null {
  if (!shouldUseCdnPreview(config, input.preview)) {
    return null;
  }

  return signAliyunTypeA(
    config.cdnBaseUrl!,
    input.objectKey,
    config.authKey!,
    config.ttlSeconds ?? DEFAULT_TTL_SECONDS,
    input.nowMs,
  );
}

export function readCdnSignerConfigFromEnv(
  env: NodeJS.ProcessEnv = process.env,
): CdnSignerConfig {
  return {
    cdnBaseUrl: env.NC_CDN_BASE_URL,
    authKey: env.NC_CDN_AUTH_KEY,
    ttlSeconds: env.NC_CDN_AUTH_TTL_SECONDS
      ? parseInt(env.NC_CDN_AUTH_TTL_SECONDS, 10)
      : DEFAULT_TTL_SECONDS,
    type: (env.NC_CDN_AUTH_TYPE as CdnSignerConfig['type']) || 'aliyun-a',
  };
}
