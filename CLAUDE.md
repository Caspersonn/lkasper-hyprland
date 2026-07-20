## Openspec integration
Before implementing a new feature always ask the user for confirmation
then ask the user if it would like to deep diver in to feature with `opsx:explore`.

## Beans
For every bug found, create a bean
If user has a new feature, ask the user if it should create bean
The bean can be used to create openspec changes

For every implemented change, link the corrosponding openspec change to the bean

## JJ
Use `jj` for commiting changes
Please don't use git directly
Never commit changes under claude ONLY ON THE USER

## TypeScript Standards
- Target: ES2022, strict mode enabled
- Runtime: Node.js 22 / browser (specify per file if mixed)
- Formatter: Prettier 3.x, tab width 2
- Linter: ESLint with @typescript-eslint/recommended-type-checked

## Type Conventions
- Prefer `interface` for object shapes that will be extended
- Use `type` for unions, intersections, mapped types
- Never use `any` — use `unknown` and narrow, or `never` for exhaustive checks
- Export types alongside implementations, not in separate files

## Key Libraries
- Validation: zod 3.x (always generate zod schemas alongside types)
- HTTP client: ky (not axios or fetch directly)
- Date handling: date-fns 3.x (not luxon or dayjs)
