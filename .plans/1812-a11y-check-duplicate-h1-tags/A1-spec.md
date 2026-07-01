# Specification: Fix Duplicate h1 Tags for Accessibility

## Problem Statement

The 100eyes application has accessibility issues related to HTML heading structure. The issue arises from misuse of the `Heading` component, which allows passing style parameters for h2/h3 sizing without specifying the semantic HTML tag itself.

### Current Situation

The `Heading` component (`app/components/heading/heading.rb`) has:
- Default tag: `:h1`
- Configurable tag via `tag:` parameter
- Configurable styles via `styles:` parameter
- SIZE_MAPPINGS: h1→alpha, h2→beta, h3→gamma (for automatic sizing)

Many view files use the component with style names like `:alpha` (h1 size), `:beta` (h2 size), or `:gamma` (h3 size) **without explicitly specifying the `tag:` parameter**. This causes:
- Multiple h1 tags on single pages (violates accessibility best practices)
- Semantic HTML misalignment (visually styled as h2/h3 but rendered as h1)

### References

- [Should you use multiple h1 heading elements on your page in 2022?](https://blog.shimin.io/should-you-use-multiple-h1-s-in-2022/)
- [MDN: Avoid using multiple h1 elements on one page](https://developer.mozilla.org/en-US/docs/Web/HTML/Element/Heading_Elements)

## Solution

Ensure all Heading component usages explicitly specify the semantic HTML tag via the `tag:` parameter, with values mapped to correct heading hierarchy:

- Primary page title → `tag: :h1`
- Section headings → `tag: :h2`
- Subsection headings → `tag: :h3`

This maintains visual consistency (styles still apply correctly) while ensuring proper semantic HTML and accessibility compliance.

## Scope

### In Scope

1. Audit all Heading component usages across view files
2. Identify pages with multiple h1 tags or missing tag specifications
3. Add explicit `tag:` parameters to all Heading components
4. Verify each page has exactly one h1 and correct semantic hierarchy
5. Test rendered output to confirm single h1 per page

### Out of Scope

- Creating new components or refactoring the Heading component itself
- Changing visual styling or CSS
- Adding automated linting/validation (optional enhancement for future)

## Affected Components

- **Component**: `app/components/heading/heading.rb` (read-only)
- **Stylesheet**: `app/components/heading/heading.css` (read-only)

## View Files to Fix

All views using `<%= c 'heading' %>` without explicit `tag:`:

1. `app/views/organizations/dashboard/index.html.erb` (line 3)
2. `app/views/requests/index.html.erb` (line 4)
3. `app/views/requests/edit.html.erb` (line 3)
4. `app/views/requests/show.html.erb` (line 8)
5. `app/views/requests/new.html.erb` (line 3)
6. `app/views/search/index.html.erb` (line 3)
7. `app/views/settings/index.html.erb` (line 3)

## Implementation Approach

1. **Audit**: Run grep to identify all Heading component usages
2. **Analyze**: Determine correct semantic tag for each usage based on page hierarchy
3. **Fix**: Add explicit `tag:` parameter to each component
4. **Verify**: Inspect rendered pages to confirm single h1 and correct hierarchy
5. **Commit**: Push changes with clear commit message

## Success Criteria

- ✅ All view files with Heading components have explicit `tag:` parameters
- ✅ Each page has exactly one h1 tag (verified by inspection)
- ✅ Semantic heading hierarchy is correct (h1 → h2 → h3, no gaps or duplicates)
- ✅ Visual styling remains unchanged (CSS classes still apply)
- ✅ Tests pass (if any existing tests cover heading structure)

## Testing Strategy

1. Manual inspection: Visit each modified page and inspect HTML in browser DevTools
2. Verify each page has only one `<h1>` tag
3. Verify heading hierarchy makes semantic sense
4. Visual regression check: Confirm styling looks the same

## Notes

- This is a straightforward fix with low risk (only adding explicit tag parameters)
- No logic changes, only parameter additions
- Maintains backward compatibility with existing styles
- Improves accessibility compliance (WCAG guideline: only one h1 per page)
