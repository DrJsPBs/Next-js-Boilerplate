import { cleanup } from '@testing-library/react';
import React from 'react';
import { afterEach, vi } from 'vitest';
import '@testing-library/jest-dom';

// Cleanup after each test case
afterEach(() => {
  cleanup();
});

// Mock IntersectionObserver
globalThis.IntersectionObserver = class IntersectionObserver {
  constructor() {}
  disconnect() {}
  observe() {}
  unobserve() {}
  takeRecords() {
    return [];
  }

  root = null;
  rootMargin = '';
  thresholds = [];
} as any;

// Mock ResizeObserver
globalThis.ResizeObserver = class ResizeObserver {
  constructor() {}
  disconnect() {}
  observe() {}
  unobserve() {}
  disconnectAll() {}
} as any;

// Mock window.matchMedia
Object.defineProperty(window, 'matchMedia', {
  writable: true,
  value: (query: string) => ({
    matches: false,
    media: query,
    onchange: null,
    addListener: () => {},
    removeListener: () => {},
    addEventListener: () => {},
    removeEventListener: () => {},
    dispatchEvent: () => {},
  }),
});

// Mock next/navigation
vi.mock('next/navigation', () => ({
  useRouter: () => ({
    push: vi.fn(),
    replace: vi.fn(),
    back: vi.fn(),
    forward: vi.fn(),
    refresh: vi.fn(),
    prefetch: vi.fn(),
  }),
  useSearchParams: () => new URLSearchParams(),
  usePathname: () => '/',
}));

// Mock next/image
vi.mock('next/image', () => ({
  default: ({ src, alt, ...props }: any) => {
    return React.createElement('img', { src, alt, ...props });
  },
}));

// Global test utilities
(globalThis as any).testUtils = {
  // Add any global test utilities here
};
