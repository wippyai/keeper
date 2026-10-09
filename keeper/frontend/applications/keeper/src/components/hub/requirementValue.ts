import type { RequirementLiteralType, RequirementValue } from '../../api/hub'

export function valueIsEmpty(value: RequirementValue | undefined): boolean {
  if (value === undefined) return true
  if (typeof value === 'string') return value.trim() === ''
  if (typeof value === 'object') return Object.keys(value).length === 0
  return false
}

export function valueText(value: RequirementValue | undefined): string {
  if (value === undefined) return ''
  return typeof value === 'string' ? value : JSON.stringify(value)
}

export function parseValue(text: string, type?: RequirementLiteralType): RequirementValue {
  if (!type || type === 'string' || text.trim() === '') return text
  let value: RequirementValue
  try {
    value = JSON.parse(text)
  } catch {
    throw new Error(`Enter a valid ${type} as JSON`)
  }
  const valid = type === 'array' ? Array.isArray(value)
    : type === 'object' ? value !== null && typeof value === 'object' && !Array.isArray(value)
    : type === 'integer' ? typeof value === 'number' && Number.isInteger(value)
    : typeof value === type
  if (!valid) throw new Error(`Enter a valid ${type} as JSON`)
  return value
}
