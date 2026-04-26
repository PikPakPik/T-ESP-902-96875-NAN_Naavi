import { naaviMediaDisplayUrl } from './naavi-media-display-url';

describe('naaviMediaDisplayUrl', () => {
  it('returns absolute URLs unchanged', () => {
    expect(
      naaviMediaDisplayUrl('https://images.unsplash.com/x', 'http://localhost:9000/naavi-images')
    ).toBe('https://images.unsplash.com/x');
    expect(
      naaviMediaDisplayUrl('http://localhost:9000/x', 'https://other/')
    ).toBe('http://localhost:9000/x');
  });

  it('extracts embedded https URL from S3-style key', () => {
    const key =
      'points_of_interest/8/https://images.unsplash.com/photo-1?auto=format&w=1200';
    expect(naaviMediaDisplayUrl(key, 'http://localhost:9000/naavi-images')).toBe(
      'https://images.unsplash.com/photo-1?auto=format&w=1200'
    );
  });

  it('joins relative keys to base', () => {
    expect(
      naaviMediaDisplayUrl('hikes/1/abc.png', 'https://s3.example/naavi-images')
    ).toBe('https://s3.example/naavi-images/hikes/1/abc.png');
  });

  it('returns null when path is empty or relative without base', () => {
    expect(naaviMediaDisplayUrl('', 'https://x')).toBeNull();
    expect(naaviMediaDisplayUrl('   ', 'https://x')).toBeNull();
    expect(naaviMediaDisplayUrl('hikes/1/a.png', '')).toBeNull();
    expect(naaviMediaDisplayUrl('hikes/1/a.png', null)).toBeNull();
  });

  it('allows absolute URL without images base', () => {
    expect(naaviMediaDisplayUrl('https://cdn.example/i.jpg', null)).toBe(
      'https://cdn.example/i.jpg'
    );
  });
});
