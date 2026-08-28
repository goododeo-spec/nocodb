import assert from 'node:assert/strict'
import { describe, it } from 'node:test'
import { canLoadAttachmentAsImage, getImagePreviewCandidates } from '../utils/fileUtils.ts'

describe('canLoadAttachmentAsImage', () => {
  it('allows image attachments', () => {
    assert.equal(canLoadAttachmentAsImage({ title: 'cover.png', mimetype: 'image/png' }), true)
  })

  it('rejects videos that have no real jpeg thumbnail', () => {
    assert.equal(
      canLoadAttachmentAsImage({
        title: 'clip.mp4',
        mimetype: 'video/mp4',
        signedUrl: 'https://example.com/clip.mp4',
      }),
      false,
    )
  })

  it('allows videos only when a signed thumbnail exists', () => {
    assert.equal(
      canLoadAttachmentAsImage(
        {
          title: 'clip.mp4',
          mimetype: 'video/mp4',
          signedUrl: 'https://example.com/clip.mp4',
          thumbnails: {
            card_cover: { signedUrl: 'https://example.com/clip-cover.jpg' },
          },
        },
        'card_cover',
      ),
      true,
    )
  })
})

describe('getImagePreviewCandidates', () => {
  const resolveSrcs = (item: Record<string, any>) => {
    const srcs: string[] = []
    if (item.signedUrl) srcs.push(item.signedUrl)
    if (item.url) srcs.push(item.url)
    return srcs
  }

  it('does not return the raw mp4 URL for videos without thumbnails', () => {
    assert.deepEqual(
      getImagePreviewCandidates(
        {
          title: 'clip.mp4',
          mimetype: 'video/mp4',
          signedUrl: 'https://example.com/clip.mp4',
        },
        'tiny',
        resolveSrcs,
      ),
      [],
    )
  })

  it('returns only the jpeg thumbnail for videos that have one', () => {
    assert.deepEqual(
      getImagePreviewCandidates(
        {
          title: 'clip.mp4',
          mimetype: 'video/mp4',
          signedUrl: 'https://example.com/clip.mp4',
          thumbnails: {
            tiny: { signedUrl: 'https://example.com/clip-tiny.jpg' },
          },
        },
        'tiny',
        resolveSrcs,
      ),
      ['https://example.com/clip-tiny.jpg'],
    )
  })

  it('keeps image attachments on the original source list', () => {
    assert.deepEqual(
      getImagePreviewCandidates(
        {
          title: 'cover.png',
          mimetype: 'image/png',
          signedUrl: 'https://example.com/cover.png',
        },
        'tiny',
        resolveSrcs,
      ),
      ['https://example.com/cover.png'],
    )
  })
})
