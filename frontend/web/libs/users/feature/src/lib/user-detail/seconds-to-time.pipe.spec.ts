import { SecondsToTimePipe } from './seconds-to-time.pipe';

describe('SecondsToTimePipe', () => {
  let pipe: SecondsToTimePipe;

  beforeEach(() => {
    pipe = new SecondsToTimePipe();
  });

  describe('Given null or undefined input', () => {
    it('When transform is called with null Then should return empty string', () => {
      expect(pipe.transform(null)).toBe('');
    });

    it('When transform is called with undefined Then should return empty string', () => {
      expect(pipe.transform(undefined)).toBe('');
    });
  });

  describe('Given invalid input', () => {
    it('When transform is called with NaN Then should return empty string', () => {
      expect(pipe.transform(NaN)).toBe('');
    });
  });

  describe('Given negative input', () => {
    it('When transform is called with negative number Then should return 0s', () => {
      expect(pipe.transform(-100)).toBe('0s');
    });
  });

  describe('Given seconds less than 60', () => {
    it('When transform is called with 0 Then should return 0s', () => {
      expect(pipe.transform(0)).toBe('0s');
    });

    it('When transform is called with 30 Then should return 30s', () => {
      expect(pipe.transform(30)).toBe('30s');
    });

    it('When transform is called with 59 Then should return 59s', () => {
      expect(pipe.transform(59)).toBe('59s');
    });
  });

  describe('Given seconds equal to or greater than 60', () => {
    it('When transform is called with exactly 60 seconds Then should return 1min', () => {
      expect(pipe.transform(60)).toBe('1min');
    });

    it('When transform is called with 90 seconds Then should return 1min', () => {
      expect(pipe.transform(90)).toBe('1min');
    });

    it('When transform is called with 150 seconds Then should return 2min', () => {
      expect(pipe.transform(150)).toBe('2min');
    });

    it('When transform is called with exactly 3600 seconds (1 hour) Then should return 1h', () => {
      expect(pipe.transform(3600)).toBe('1h');
    });

    it('When transform is called with 3660 seconds (1h 1min) Then should return 1h 1min', () => {
      expect(pipe.transform(3660)).toBe('1h 1min');
    });

    it('When transform is called with 7200 seconds (2 hours) Then should return 2h', () => {
      expect(pipe.transform(7200)).toBe('2h');
    });

    it('When transform is called with 7320 seconds (2h 2min) Then should return 2h 2min', () => {
      expect(pipe.transform(7320)).toBe('2h 2min');
    });

    it('When transform is called with decimal seconds Then should floor the value', () => {
      expect(pipe.transform(90.7)).toBe('1min');
    });
  });
});
