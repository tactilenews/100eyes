# Implementation Plan: Fix Duplicate h1 Tags for Accessibility

## Prerequisites

None. The task is self-contained within the Rails codebase.

## Context

The 100eyes Rails application uses a `Heading` component (located at `app/components/heading/heading.rb`) that accepts a `tag:` parameter to specify the HTML tag (h1, h2, h3, etc.). The component defaults to `:h1` if no `tag:` is provided.

**Current Issue**: Many views use the Heading component with style names like `:alpha` (h1 sizing), `:beta` (h2 sizing), or `:gamma` (h3 sizing) **without explicitly specifying the `tag:` parameter**. This causes:
- Multiple h1 tags on single pages (accessibility violation)
- Semantic HTML misalignment (h2/h3 sized text rendered as h1 tags)

**After Implementation**: All Heading component usages will explicitly specify the semantic tag that matches the intended hierarchy, ensuring each page has only one h1 tag and proper semantic HTML structure.

## Important Files

- Component definition: `app/components/heading/heading.rb`
- Styling: `app/components/heading/heading.css`
- View files using Heading (all require `tag:` parameter):
  - `app/views/organizations/dashboard/index.html.erb`
  - `app/views/requests/index.html.erb`
  - `app/views/requests/edit.html.erb`
  - `app/views/requests/show.html.erb`
  - `app/views/requests/new.html.erb`
  - `app/views/search/index.html.erb`
  - `app/views/settings/index.html.erb`

## Implementation Steps

### Step 1: Audit All Heading Component Usages

Run the following command to find all usages of the Heading component:

```bash
grep -rn "c 'heading'" app/views --include="*.erb"
```

Create a comprehensive list of all instances, noting:
- File path
- Current parameters (style, tag, etc.)
- Whether `tag:` is explicitly specified
- The intended semantic level (h1, h2, h3, etc.)

### Step 2: Analyze Heading Hierarchy on Each Page

For each view file using the Heading component, determine:
- How many Heading components are on the page
- What semantic hierarchy should exist (one h1, then h2s, then h3s, etc.)
- Which Heading component should be the main h1 (usually the page title)
- What tag each other Heading should have

Document the findings for each affected view.

### Step 3: Fix Heading Components in View Files

For each view file identified in Step 1:

1. Identify the main page heading (should be h1)
2. Add `tag: :h1` to the main page heading if not already present
3. Change any secondary headings to `tag: :h2` or lower as appropriate
4. Verify that no page has multiple h1 tags

Key mapping to remember:
- Primary page title → `tag: :h1`
- Section headings → `tag: :h2`
- Subsection headings → `tag: :h3`

View files to fix:
- `app/views/organizations/dashboard/index.html.erb` — Line 3: Add `tag: :h1`
- `app/views/requests/index.html.erb` — Line 4: Verify/add `tag: :h1`
- `app/views/requests/edit.html.erb` — Line 3: Verify/add `tag: :h1`
- `app/views/requests/show.html.erb` — Line 8: Verify/add `tag: :h1`
- `app/views/requests/new.html.erb` — Line 3: Verify/add `tag: :h1`
- `app/views/search/index.html.erb` — Line 3: Add `tag: :h1`
- `app/views/settings/index.html.erb` — Line 3: Verify/add `tag: :h1`

### Step 4: Verify Changes

After fixing all view files:

1. Start the Rails development server: `rails server`
2. Visit each modified page in a browser
3. Use browser DevTools (Inspect Element) to verify:
   - Each page has exactly one `<h1>` tag
   - Semantic heading hierarchy is correct (h1 → h2 → h3, no gaps)
   - Visual styling matches the intended heading level

Alternatively, use a script or gem to automatically detect multiple h1 tags:

```bash
grep -r "<h1" app/views --include="*.erb" | wc -l
```

For each view, manually render and inspect the HTML output.

### Step 5: Commit Changes

Stage all modified view files:

```bash
git add app/views
```

Commit with a clear message:

```bash
git commit -m "fix(a11y): ensure single h1 per page and correct semantic heading structure

- Add explicit tag: parameter to all Heading components
- Map style names to correct semantic tags (alpha→h1, beta→h2, gamma→h3)
- Verify each page has exactly one h1 tag
- Maintain visual consistency with existing styles

Fixes #1812"
```

### Step 6: Write a Handover Document

Write a **handover document**. This document must contain the list of all files you updated. Also, summarize the changes made in a very concise way. Add only relevant information that will help your teammates understand what's new. Do not mention obvious information. It's not a course or a tutorial, if there is nothing to explain, then do not explain. Write this handover document in `.plans/1812-a11y-check-duplicate-h1-tags/A1-plan.summary.md`. Ignore lint errors (formatting issues) in this file. At the end, give the path of this handover file to the user.

---

Do not trust this plan blindly. Be sure you understand the codebase and the plan by yourself before applying it.

**IMPORTANT**: Do NOT use external search tools (Context7, web search, documentation fetching) during implementation unless explicitly allowed in this plan. All context should be provided in this plan or discoverable in the codebase.
