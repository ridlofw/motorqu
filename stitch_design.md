---
name: MotorQu Design System
colors:
  surface: '#f8fafc'
  surface-dim: '#f1f5f9'
  surface-bright: '#ffffff'
  surface-container-lowest: '#ffffff'
  surface-container-low: '#f8fafc'
  surface-container: '#f1f5f9'
  surface-container-high: '#e2e8f0'
  surface-container-highest: '#cbd5e1'
  on-surface: '#0f172a'
  on-surface-variant: '#64748b'
  outline: '#94a3b8'
  outline-variant: '#e2e8f0'
  primary: '#1976d2'
  on-primary: '#ffffff'
  primary-container: '#1565c0'
  on-primary-container: '#e3f2fd'
  secondary: '#2e7d32'
  on-secondary: '#ffffff'
  secondary-container: '#e8f5e9'
  on-secondary-container: '#1b5e20'
  tertiary: '#f57c00'
  on-tertiary: '#ffffff'
  tertiary-container: '#fff3e0'
  on-tertiary-container: '#e65100'
  error: '#d32f2f'
  on-error: '#ffffff'
  error-container: '#ffebee'
  on-error-container: '#b71c1c'
  background: '#f8fafc'
  on-background: '#0f172a'
typography:
  display-lg:
    fontFamily: Plus Jakarta Sans
    fontSize: 26px
    fontWeight: '700'
    lineHeight: 34px
  headline-md:
    fontFamily: Plus Jakarta Sans
    fontSize: 20px
    fontWeight: '700'
    lineHeight: 28px
  title-sm:
    fontFamily: Plus Jakarta Sans
    fontSize: 16px
    fontWeight: '600'
    lineHeight: 22px
  body-md:
    fontFamily: Inter
    fontSize: 14px
    fontWeight: '400'
    lineHeight: 20px
  body-sm:
    fontFamily: Inter
    fontSize: 12px
    fontWeight: '400'
    lineHeight: 16px
  label-caps:
    fontFamily: Inter
    fontSize: 11px
    fontWeight: '700'
    lineHeight: 14px
rounded:
  sm: 0.25rem
  DEFAULT: 0.5rem
  md: 0.75rem
  lg: 1rem
  xl: 1.25rem
  full: 9999px
spacing:
  base: 8px
  xs: 4px
  sm: 8px
  md: 16px
  lg: 20px
  xl: 24px
  gutter: 16px
---

## Brand & Style
Modern, trustworthy, and clean automotive utility design system for MotorQu (motorcycle oil change & maintenance tracker). Primary royal electric blue (`#1976D2`) with deep indigo gradient (`#1565C0`), high-contrast daylight card surfaces (`#FFFFFF`), light canvas (`#F8FAFC`), forest green for safe states (`#2E7D32`), amber for warnings (`#F57C00`), and crimson red for overdue status (`#D32F2F`). Mobile-first ergonomic touch targets, rounded pill indicators, and high visual legibility.

## Components
### Bottom Navigation
Three-item navigation bar: 'Motor' on the left, an elevated floating circular '+' button with a vibrant blue-indigo gradient in the center, and 'Profil' on the right.

### Motorcycle Status Card
White card with 16px corner radius. Displays motorcycle icon avatar, nickname, model, plate number, ownership badge ('Pribadi' or 'Grup'), last oil odometer with service date, target odometer, and a colored status indicator pill.

### Oil Record Timeline
Vertical timeline featuring circular blue checkmark nodes connected by subtle vertical indicator lines, paired with timestamped cards displaying recorded odometer and service user.
