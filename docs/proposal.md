# Proposal: XPascal / XRTL Platform

> A modern FreePascal-powered application platform for desktop, web, and server development.  
> Tauri-like mental model, HTML component UI, MVVM, batteries included, CLI-first, CI/CD-first, AI-agent-friendly.

## 1. Executive Summary

This proposal defines a new software development platform built on top of FreePascal, but intentionally not compatible with Delphi or Lazarus at the framework/IDE level.

The goal is not to create another Lazarus IDE, another Delphi clone, or a nostalgic Pascal toolkit. The goal is to create a modern, approachable, productive application platform for building beautiful cross-platform desktop apps, web apps, and server-side services using FreePascal as the compiler and Pascal as the core language.

One important lesson from Delphi and Lazarus should be preserved: their
DataSource/Data Binding model is extremely strong for business applications.
XPascal should not be Delphi/Lazarus compatible, but it should learn from the
productivity of data-aware components, master-detail binding, grids, forms, and
rapid database application development.

The platform should feel closer in spirit to:

- Tauri for desktop architecture
- Ruby on Rails / Django for batteries-included productivity
- FastAPI for simple server-side ergonomics
- Flutter + Serverpod for full-stack app/platform thinking
- Hotwire Native for web-first app delivery
- Xojo for beginner-friendly documentation and approachable app-building workflow

But it should avoid the weaknesses the user has suffered from:

- Lazarus/FPC old-school documentation and fragmented tooling
- Xojo’s weak command-line, CI/CD, and AI-agent story
- Binary or opaque project formats
- IDE-first workflows that trap the developer
- Frameworks that are powerful but unfriendly to new developers and AI agents

Working codename:

```text
XPascal
```

Runtime/library codename:

```text
XRTL
```

### 1.1 Bootstrap Addendum

The bootstrap implementation has refined several planning assumptions:

- FreePascal is pinned to version `3.3.1`.
- The first supported bootstrap targets are Windows x86_64, macOS Apple Silicon aarch64, and Linux x86_64 / Ubuntu 26.04 LTS.
- macOS Intel x86_64 is intentionally not supported.
- Windows, macOS Apple Silicon, and Linux x86_64 bootstrap validation have passed.
- Windows, macOS Apple Silicon, and Linux FPC snapshot SHA256 values are pinned and verified by installer scripts before extraction.
- Documentation is split into three early streams:
  - Captain's Log: a timestamped human-readable work journal.
  - Developer Docs EN/TH: HTML-oriented developer documentation, English first and Thai alongside it.
- Proposal HTML: this proposal should be generated as linkable HTML in addition to the Markdown source.
- Codex remains responsible for source-of-truth verification, edits, tests, issues, branches, commits, and PRs.
- GLM should assist as a documentation drafter/reviewer through task packets saved under `ai/briefs/`, with raw outputs and Codex review notes preserved under `ai/glm-outputs/` and `ai/reviews/`.
- GitHub issues are treated as project planning artifacts, not throwaway task notes. Each issue should reference relevant proposal sections, define scope and acceptance criteria, and be kept in sync with PR evidence and documentation.
- The operating rule after the bootstrap merge is: no non-trivial work without a GitHub issue; after implementation, compare the completed work back against that issue's acceptance criteria and validation plan before closing.

## 2. Product Vision

XPascal is a modern app platform where developers can build:

- desktop apps
- local-first apps
- web apps
- server APIs
- internal tools
- SaaS backends
- future mobile shells

using:

- FreePascal compiler
- XRTL runtime libraries
- MVVM architecture
- DataSource/Data Binding for business applications
- HTML-compatible component UI
- a Tauri-like desktop shell
- CLI-first tooling
- structured project files
- excellent English and Thai documentation
- workflows designed from day one for Codex, GLM, CI/CD, and human developers

The developer should be able to start with:

```bash
xpc new app mycrm
cd mycrm
xpc run desktop
```

and later:

```bash
xpc run web
xpc test
xpc build
xpc package
```

The IDE should eventually be a first-class product, but the platform must not depend on the IDE. The CLI and project format are the foundation. The IDE is a visual frontend over the same open structure.

## 3. Core Principles

### 3.1 CLI First, IDE Friendly

Everything must work from the command line:

```bash
xpc new
xpc build
xpc run
xpc test
xpc format
xpc lint
xpc package
xpc generate
xpc doctor
```

The IDE should call the same tools internally. This avoids the Xojo problem where the IDE becomes a closed universe.

### 3.2 HTML UI First

The UI layer should use HTML-like tags as the primary format.

Reasons:

- compatible with existing HTML/CSS mental models
- friendlier to new developers
- easier for designers to inspect
- easier for AI agents to edit
- easy to diff in Git
- works with existing HTML tooling where possible
- easier to render in WebView desktop, browser web, docs, preview, and tests

Example:

```html
<x-page title="Customers">
  <x-stack gap="md">
    <x-heading level="1">Customers</x-heading>

    <x-form bind:submit="SaveCustomer">
      <x-input label="Name" bind:value="Customer.Name" required />
      <x-input label="Email" bind:value="Customer.Email" type="email" />
      <x-button command="SaveCustomer" variant="primary">
        Save
      </x-button>
    </x-form>
  </x-stack>
</x-page>
```

### 3.3 Pascal Core Logic

Business logic, ViewModels, validation, services, database access, jobs, and system APIs should live in Pascal.

Example:

```pascal
type
  TCustomerViewModel = class(TViewModel)
  private
    FCustomer: TCustomer;
  published
    property Customer: TCustomer read FCustomer write FCustomer;
    function CanSave: Boolean;
    procedure SaveCustomer;
  end;
```

This keeps the app strongly typed while leaving UI expression approachable.

### 3.4 MVVM by Default

The default architecture is MVVM:

```text
Model      = domain/data
View       = HTML component template
ViewModel  = state, commands, validation, presentation logic
Binding    = View <-> ViewModel sync
```

This is essential because:

- ViewModels are unit-testable
- UI can be generated/rendered in desktop and web
- AI agents can reason about separated responsibilities
- designers can work on view files
- backend and frontend can share typed domain concepts

### 3.5 DataSource And Data Binding As A First-Class Feature

Delphi VCL and Lazarus LCL did something extremely well: data-aware components.

For business applications, the ability to bind a grid, form, navigator, lookup,
master-detail view, or editor directly to structured data is a superpower.

XPascal should keep the spirit of that model, but redesign it for:

- MVVM
- HTML component UI
- testability
- async data loading
- web/desktop shared rendering
- AI-readable project files
- modern API/data sources

This means XPascal needs a modern data binding layer, not just simple property
binding.

Core concepts:

```text
DataSource
DataSet / Query
CollectionView
CurrentRecord
SelectedRecord
MasterDetailLink
LookupSource
CommandBinding
ValidationBinding
ChangeTracking
```

Example:

```html
<x-data-source id="customers" bind:source="Customers" key="Id" />

<x-data-grid datasource="customers" selected.bind="SelectedCustomer">
  <x-column field="Name" title="Name" />
  <x-column field="Email" title="Email" />
</x-data-grid>

<x-form datasource="customers" record.bind="SelectedCustomer">
  <x-input field="Name" label="Name" />
  <x-input field="Email" label="Email" />
</x-form>
```

Master-detail:

```html
<x-data-source id="customers" bind:source="Customers" key="Id" />
<x-data-source
  id="orders"
  bind:source="Orders"
  master="customers"
  master-field="Id"
  detail-field="CustomerId" />

<x-data-grid datasource="customers" selected.bind="SelectedCustomer" />
<x-data-grid datasource="orders" />
```

The developer should feel the same productivity magic as Delphi/Lazarus
DataSource, but with modern architecture and web-ready UI.

#### 3.5.1 Non-Negotiable Data Binding Requirement

This is not a later convenience feature.

For XPascal to become a serious business application platform, the first real
version must prove that developers can build database-heavy screens quickly.

The platform is not considered successful until it can comfortably build:

- customer/order master-detail screens
- invoice or quotation forms with line-item grids
- searchable data tables
- editable grids with validation
- lookup fields backed by another data source
- record navigation
- dirty state and change tracking
- save/cancel workflows
- server-backed pagination
- local SQLite-backed CRUD screens
- REST-backed CRUD screens

The target feeling:

```text
Delphi/Lazarus speed for business forms,
modern HTML UI flexibility,
testable MVVM architecture,
CLI/CI/AI-friendly source files.
```

If this part is weak, XPascal becomes only another Pascal webview framework.
If this part is strong, XPascal has a real reason to exist.

### 3.6 Batteries Included, Escape Hatches Allowed

The platform should be opinionated enough to be productive:

- routing
- components
- validation
- forms
- logging
- config/env
- database
- REST client/server
- auth/session
- jobs
- tests
- packaging
- docs generator

But advanced users must be able to override lower levels.

This is “convention over configuration,” not “locked down forever.”

### 3.7 AI-Agent Friendly From Day One

Every source artifact should be plain text, structured, and stable:

```text
xproject.toml
app/viewmodels/*.pas
app/views/*.xui.html
app/routes/*.pas
app/models/*.pas
assets/theme/*.css
tests/*.pas
```

AI agents must be able to:

- inspect project structure
- modify a view without breaking binary IDE state
- run tests
- generate components
- review diffs
- update docs
- run CLI build
- understand conventions from `AGENTS.md`

## 4. What This Is Not

XPascal is not:

- a Lazarus fork
- a Delphi clone
- an LCL compatibility layer
- a VCL compatibility layer
- a PureBasic replacement
- a React Native clone
- an Electron clone
- a web framework only
- an IDE-only product

Compatibility with Delphi/Lazarus is intentionally not a goal.

The goal is a clean modern platform powered by FreePascal.

## 5. Architecture Overview

```text
XPascal Platform
├─ XCLI
│  ├─ project creation
│  ├─ build/run/test/package
│  ├─ code generation
│  ├─ diagnostics
│  └─ CI/CD integration
│
├─ XRTL
│  ├─ HTTP client/server
│  ├─ JSON
│  ├─ database
│  ├─ data sources
│  ├─ collection views
│  ├─ data binding primitives
│  ├─ config/env
│  ├─ logging
│  ├─ validation
│  ├─ jobs
│  ├─ auth/session
│  ├─ file/process/platform APIs
│  └─ testing utilities
│
├─ XMVVM
│  ├─ ViewModel base classes
│  ├─ observable state
│  ├─ commands
│  ├─ validation
│  ├─ data-source aware ViewModels
│  ├─ master-detail state
│  ├─ binding engine
│  └─ ViewModel testing
│
├─ XUI
│  ├─ HTML-compatible component templates
│  ├─ component library
│  ├─ data-aware components
│  ├─ theme tokens
│  ├─ partial update protocol
│  ├─ accessibility helpers
│  └─ preview renderer
│
├─ XDesktop
│  ├─ WebView shell
│  ├─ native bridge
│  ├─ native menus
│  ├─ file dialogs
│  ├─ notifications
│  ├─ tray
│  └─ packaging
│
├─ XServer
│  ├─ routing
│  ├─ typed request/response
│  ├─ middleware
│  ├─ OpenAPI-style metadata
│  ├─ background jobs
│  └─ deployment helpers
│
└─ XIDE
   ├─ project explorer
   ├─ code editor
   ├─ visual component designer
   ├─ property inspector
   ├─ ViewModel binding picker
   ├─ build/test/debug panel
   └─ docs/tutorial browser
```

## 6. Desktop Architecture

The desktop runtime should follow the Tauri mental model:

```text
Trusted native backend
  = FreePascal app runtime

Untrusted frontend
  = WebView-rendered HTML/CSS/JS

Communication
  = explicit command/message bridge
```

### 6.1 Why Tauri Mental Model Fits

Tauri uses a native backend plus system WebView model, with frontend-to-backend communication through explicit commands/message passing. This matches the desired architecture better than Electron because:

- smaller footprint than bundling full Chromium
- clearer security boundary
- web UI flexibility
- native platform APIs exposed only through explicit bridge commands
- good mental model for desktop + web shared UI

XPascal should follow this model, but with FreePascal instead of Rust.

### 6.2 WebView Strategy

Initial target:

```text
Windows: WebView2
macOS: WKWebView
Linux: WebKitGTK
```

Phase 1 may target Windows first if necessary.

The platform should hide WebView details behind:

```pascal
XDesktop.Window
XDesktop.Bridge
XDesktop.Dialogs
XDesktop.Notifications
XDesktop.Clipboard
```

### 6.3 Native Bridge

JavaScript must not directly access filesystem, process, network, or OS features.

Use an allowlisted command bridge:

```json
{
  "command": "dialog.openFile",
  "payload": {
    "filters": ["*.png", "*.jpg"]
  }
}
```

Pascal side:

```pascal
XBridge.Register('dialog.openFile', TOpenFileCommand);
```

Bridge commands should be:

- typed
- documented
- testable
- permissioned
- loggable

## 7. HTML Tag UI vs Pascal-First UI

The preferred UI format is HTML-compatible tags.

However, Pascal-first UI also has real advantages. The platform should support HTML-first as default and optionally allow Pascal-first construction for special cases.

### 7.1 HTML Tag UI Advantages

HTML tag UI wins for:

- designer friendliness
- compatibility with existing HTML/CSS tools
- AI editing
- Git diff readability
- documentation examples
- visual preview
- web target reuse
- approachable learning curve
- easier theming
- easier integration with browser accessibility tooling

Example:

```html
<x-card>
  <x-heading level="2">Customer</x-heading>
  <x-input label="Email" bind:value="Email" />
</x-card>
```

### 7.2 Pascal-First UI Advantages

Pascal-first UI can be better for:

1. **Autocomplete and type safety**

   IDE can complete component APIs directly:

   ```pascal
   Page
     .Card
     .Input('Email')
     .Required
     .Validate(TEmailValidator.Create);
   ```

2. **Refactoring**

   Renaming methods/properties/classes is easier in Pascal code than in string-based templates.

3. **Debugging**

   Pascal-first UI can be debugged step-by-step like normal code.

4. **Dynamic UI**

   Complex generated forms, dynamic dashboards, schema-driven admin pages, and deeply conditional layouts can be easier in Pascal.

5. **Static analysis**

   The compiler can catch mistakes earlier if components are strongly typed.

6. **No template parser edge cases**

   Some errors become Pascal compiler errors rather than runtime template errors.

### 7.3 Recommended Position

Default:

```text
HTML tag UI
```

Advanced escape hatch:

```text
Pascal-first UI builder
```

The two should compile into the same internal component tree:

```text
HTML template -> XUI AST -> render/bind
Pascal builder -> XUI AST -> render/bind
```

This gives the best of both worlds.

## 8. UI Component System

XUI should provide a fixed, themed component library.

Initial components:

```text
x-page
x-layout
x-stack
x-grid
x-card
x-heading
x-text
x-button
x-link
x-form
x-input
x-textarea
x-select
x-checkbox
x-radio
x-table
x-list
x-modal
x-tabs
x-alert
x-badge
x-menu
x-toolbar
x-sidebar
x-dialog
```

Business/data-aware components must be first-class, not optional add-ons:

```text
x-data-source
x-data-grid
x-data-table
x-data-form
x-data-navigator
x-lookup
x-master-detail
x-pagination
x-filter-bar
x-search-box
x-sort-header
x-record-editor
x-record-actions
```

### 8.1 Data Grid / Table Requirements

The grid/table component is critical for business applications.

It must support:

- binding to DataSource / CollectionView
- selected row binding
- master-detail links
- editable and read-only modes
- sorting
- filtering
- pagination
- virtual scrolling for large datasets
- column resizing
- column visibility
- custom cell templates
- lookup columns
- validation states
- keyboard navigation
- accessible table semantics
- export hooks
- row actions
- optimistic update states

Example:

```html
<x-data-grid
  datasource="customers"
  selected.bind="SelectedCustomer"
  mode="editable">

  <x-column field="Name" title="Customer" sortable />
  <x-column field="Email" title="Email" />
  <x-column field="Status" title="Status" lookup="customerStatus" />
  <x-actions>
    <x-button command="EditCustomer">Edit</x-button>
    <x-button command="DeleteCustomer" variant="danger">Delete</x-button>
  </x-actions>
</x-data-grid>
```

Master-detail example:

```html
<x-master-detail>
  <x-data-grid datasource="customers" selected.bind="SelectedCustomer" />
  <x-data-grid datasource="orders" master="customers" />
</x-master-detail>
```

The goal is business-app productivity comparable to Delphi/Lazarus, but with a
modern HTML component model.

The component system should be:

- themeable
- accessible by default
- keyboard friendly
- responsive
- documented with examples
- usable in desktop and web

## 9. Binding Syntax

Recommended template syntax:

```html
<x-input label="Email" bind:value="Customer.Email" />
<x-button command="SaveCustomer" disabled.bind="!CanSave">
  Save
</x-button>
```

Principles:

- bindings should reference ViewModel properties
- commands should map to ViewModel methods
- validation should be declarative where possible
- events should be explicit
- string magic should be minimized

Possible syntax:

```html
bind:value="Email"
on:click="Save"
if="CanShowAdvanced"
repeat:item="Customers"
```

The exact syntax needs design, but it should stay close enough to HTML conventions to feel natural.

### 9.1 Data Binding Syntax

Data binding must support both simple form binding and business application binding.

Form binding:

```html
<x-input label="Name" bind:value="Customer.Name" />
<x-input label="Email" bind:value="Customer.Email" />
```

Collection binding:

```html
<x-data-grid datasource="Customers" selected.bind="SelectedCustomer" />
```

Master-detail binding:

```html
<x-data-grid datasource="Customers" selected.bind="SelectedCustomer" />

<x-data-grid
  datasource="Orders"
  master="Customers"
  master-key="Id"
  detail-key="CustomerId" />
```

Lookup binding:

```html
<x-select
  label="Status"
  bind:value="Customer.StatusId"
  lookup="CustomerStatuses"
  text-field="Name"
  value-field="Id" />
```

Validation binding:

```html
<x-input
  label="Email"
  bind:value="Customer.Email"
  errors.bind="Customer.Errors.Email" />
```

The design goal is to make common database UI feel as immediate as Delphi/Lazarus DataSource/DataSet workflows, while keeping the implementation modern, testable, and suitable for HTML components.

## 10. MVVM Design

### 10.1 Model

Models represent domain data:

```pascal
type
  TCustomer = class
  published
    property Name: string;
    property Email: string;
  end;
```

### 10.2 ViewModel

ViewModels own state and commands:

```pascal
type
  TCustomerViewModel = class(TViewModel)
  private
    FCustomer: TCustomer;
  published
    property Customer: TCustomer read FCustomer write SetCustomer;
    property IsSaving: Boolean read FIsSaving;
    function CanSave: Boolean;
    procedure SaveCustomer;
  end;
```

### 10.3 View

Views are HTML component templates:

```html
<x-page title="Customer">
  <x-form bind:submit="SaveCustomer">
    <x-input label="Name" bind:value="Customer.Name" required />
    <x-input label="Email" bind:value="Customer.Email" type="email" />
    <x-button command="SaveCustomer" disabled.bind="!CanSave">
      Save
    </x-button>
  </x-form>
</x-page>
```

### 10.4 Testing

ViewModels should be testable without launching a UI:

```pascal
procedure Test_CustomerCannotSaveWithoutEmail;
begin
  VM.Customer.Name := 'Jane';
  VM.Customer.Email := '';
  AssertFalse(VM.CanSave);
end;
```

### 10.5 ViewModel DataSource Pattern

Business ViewModels should expose data sources directly instead of forcing every screen to hand-roll collection, selection, validation, and detail state.

Example:

```pascal
type
  TCustomerListViewModel = class(TViewModel)
  private
    FCustomers: TXDataSource<TCustomer>;
    FOrders: TXDataSource<TOrder>;
  published
    property Customers: TXDataSource<TCustomer> read FCustomers;
    property Orders: TXDataSource<TOrder> read FOrders;
    property SelectedCustomer: TCustomer read GetSelectedCustomer;

    procedure NewCustomer;
    procedure SaveCustomer;
    procedure DeleteCustomer;
  end;
```

The framework should provide standard ViewModel primitives:

- `TXDataSource<T>`
- `TXCollectionView<T>`
- `TXCurrentRecord<T>`
- `TXSelection<T>`
- `TXMasterDetailLink`
- `TXLookupSource<T>`
- `TXChangeTracker`
- `TXValidationResult`

This keeps repetitive business app plumbing out of application code.

## 11. XRTL

XRTL is the modern runtime library layer on top of FPC RTL/FCL.

It should reuse strong existing open-source libraries where appropriate, but expose a clean and consistent developer experience.

### 11.1 Dependency Provenance Gate

XRTL may adopt, wrap, or learn from strong open-source projects, but only after the candidate is recorded in the dependency provenance register.

Before any third-party code is copied, vendored, linked, wrapped, or exposed through a public XRTL API, the project must record:

- canonical upstream location
- exact source revision, release, or package reference
- license files and redistribution obligations
- platform support evidence for Windows, macOS Apple Silicon, and Ubuntu
- maintenance/activity signal
- feature fit and known risks
- decision status
- rationale for direct use, wrapper use, inspiration-only use, or rejection
- linked issue, PR, and ADR when the choice affects public behavior

The register lives at `docs/dependencies.html`. Issue #28 records database and web server candidate research, but candidates remain research-only until a later implementation issue accepts a specific adoption decision. The first concrete slices are intentionally small: local SQLite through SQLDB for `XRTL.Database`, HTTP provider research before any FCL-Web/fphttpserver fork or wrapper, and an XRTL-owned middleware design credited to Rack/Horse-style references.

This keeps the platform practical without turning XRTL into an unreviewed bundle of borrowed code.

### 11.2 XRTL Modules

```text
X.Core
X.Config
X.Env
X.Json
X.Http
X.Rest
X.Db
X.Sqlite
X.Postgres
X.Data
X.DataSource
X.Binding
X.CollectionView
X.Log
X.Validation
X.Auth
X.Session
X.Crypto
X.Mail
X.Job
X.Queue
X.FileSystem
X.Process
X.Desktop
X.Test
```

### 11.3 REST Client

Example:

```pascal
var Response := XRest
  .Get('https://api.example.com/customers')
  .BearerToken(Config.ApiToken)
  .AcceptJson
  .Send;
```

### 11.4 Server Routing

FastAPI-inspired, but Pascal-native:

```pascal
App.Get('/customers/:id',
  procedure(Ctx: TXContext)
  begin
    Ctx.Json(CustomerService.Find(Ctx.ParamInt('id')));
  end);
```

Later:

```pascal
[Get('/customers/:id')]
function GetCustomer(Id: Integer): TCustomerDto;
```

Start explicit. Add attribute magic later.

### 11.5 X.Data

`X.Data` is the business data layer that gives XPascal its Delphi/Lazarus-style productivity without requiring Delphi/Lazarus compatibility.

It should include:

- typed data sources
- query-backed data sources
- in-memory data sources
- REST-backed data sources
- current record tracking
- selection state
- master-detail relationships
- lookup lists
- dirty/change tracking
- optimistic update support
- validation state
- transaction helpers
- paging and virtual loading contracts

Example:

```pascal
Customers := XData.Source<TCustomer>
  .FromQuery(Db.Query('select * from customers'))
  .Key('Id')
  .OrderBy('Name');

Orders := XData.Source<TOrder>
  .FromQuery(Db.Query('select * from orders'))
  .Key('Id')
  .Master(Customers, 'CustomerId');
```

The API should make the common case short, but still allow direct SQL, REST, or custom repository implementations behind the same component-facing contract.

## 12. Server Framework

The server framework should be easy like FastAPI:

```pascal
App := XServer.Create;

App.Get('/health',
  procedure(Ctx: TXContext)
  begin
    Ctx.Json(['status', 'ok']);
  end);

App.Post('/customers',
  procedure(Ctx: TXContext)
  var Input: TCustomerInput;
  begin
    Input := Ctx.Body.As<TCustomerInput>;
    Ctx.Json(CustomerService.Create(Input));
  end);

App.Run;
```

Features:

- routing
- middleware
- JSON body parsing
- typed DTOs
- validation
- static files
- templates/components
- sessions
- auth
- background jobs
- OpenAPI-style metadata later

## 13. Project Structure

Recommended project layout:

```text
myapp/
  xproject.toml
  AGENTS.md
  README.md

  app/
    models/
      customer.pas

    viewmodels/
      customer_vm.pas

    datasources/
      customer_source.pas
      order_source.pas

    views/
      customer.xui.html
      dashboard.xui.html

    components/
      app_button.xui.html
      app_layout.xui.html

    routes/
      web.pas
      api.pas

    services/
      customer_service.pas

  assets/
    styles/
      theme.css
    images/

  tests/
    unit/
    integration/
    e2e/

  build/
  dist/
```

## 14. CLI Design

The CLI should be the heart of the platform.

Commands:

```bash
xpc new app myapp
xpc run desktop
xpc run web
xpc run api
xpc build
xpc test
xpc test unit
xpc test e2e
xpc package
xpc generate viewmodel Customer
xpc generate component AppButton
xpc doctor
xpc format
xpc lint
xpc docs serve
```

### 14.1 `xpc doctor`

Checks:

- FPC installed
- target platform toolchain
- WebView runtime
- package dependencies
- test tools
- environment variables
- project file health

### 14.2 CI/CD

Generated projects should include:

```text
.github/workflows/ci.yml
```

Default CI:

```bash
xpc doctor
xpc build
xpc test
```

Later:

```bash
xpc package desktop
xpc publish
```

## 15. IDE Strategy

Do not build the IDE first.

The IDE should be a visual frontend over the CLI and project format.

Initial IDE features:

- open project
- project explorer
- code editor
- XUI preview
- ViewModel binding inspector
- property inspector for components
- build/run/test panel
- integrated docs/tutorials
- AI-agent task panel

The IDE should never be the only way to build or edit a project.

## 16. Documentation Strategy

Documentation is a core product feature, not an afterthought.

The user explicitly called out that:

- Xojo wins on approachable docs
- Lazarus/FPC docs feel old-school
- modern Gen Z frameworks like ElysiaJS feel far ahead in docs/readability

Therefore XPascal must ship with excellent documentation from day one.

### 16.1 Documentation Goals

Docs must be:

- English first
- Thai first-class, not machine-translated afterthought
- example-heavy
- beginner-friendly
- searchable
- versioned
- copy-paste runnable
- linked directly from compiler/runtime errors where possible

### 16.2 Documentation Structure

```text
docs/
  en/
    getting-started/
    tutorials/
    guides/
    reference/
    cookbook/
    examples/
    migration-thinking/

  th/
    getting-started/
    tutorials/
    guides/
    reference/
    cookbook/
    examples/
```

### 16.3 Required First Tutorials

1. Install XPascal
2. Create your first desktop app
3. Build a form with MVVM
4. Save data to SQLite
5. Call a REST API
6. Build a small CRM
7. Package a desktop app
8. Run tests
9. Deploy a web app
10. Use Codex + GLM to modify an app safely

### 16.4 Documentation Style

Every concept page should include:

- short explanation
- why it exists
- minimal example
- complete runnable example
- common mistakes
- next steps

Example:

```markdown
# ViewModels

ViewModels hold screen state and commands.

## Minimal Example

...

## Common Mistakes

- Putting database code directly in the View
- Binding to private fields
- Returning unvalidated state

## Try It

xpc new tutorial viewmodel-counter
```

### 16.5 Thai Documentation

Thai docs should not be literal translation only.

They should use natural Thai explanations:

- less academic
- practical examples
- terminology consistency
- English terms preserved when developers expect them

Example terminology:

```text
ViewModel = วิวโมเดล
Binding = binding / การผูกข้อมูล
Command = command / คำสั่งจากหน้าจอ
Component = component
Route = route
```

## 17. Codex + GLM Collaboration Workflow

This is critical.

The platform should be designed so Codex and GLM can divide work well without wasting tokens or sacrificing quality.

### 17.1 Problem

If Codex does everything:

- quality is high
- tool execution is strong
- but cost/time/token usage may be high

If GLM does everything:

- cheaper thinking may be possible
- but no direct tool access
- higher risk of schema mismatch, hallucination, or unverified output

Best workflow:

```text
GLM does heavy drafting/review/planning
Codex supervises, applies, tests, verifies
```

### 17.2 Recommended Role Split

Codex:

- source-of-truth keeper
- planner
- task splitter
- prompt writer
- final approver
- file editor
- test runner
- integration owner
- quality gate

GLM:

- content drafter
- UX reviewer
- backend reviewer
- test-plan generator
- documentation drafter
- alternative architecture explorer
- risk checklist generator

Sub-agents:

- source research
- parallel review
- isolated test/report tasks
- independent critique

### 17.3 Token-Saving Strategy

Use a layered context model:

```text
Level 1: Product brief, always short
Level 2: Task-specific context
Level 3: File excerpts only when needed
Level 4: Full files only for Codex/tool execution
```

Do not send the whole codebase to GLM.

Instead:

```text
Send:
- source brief
- acceptance criteria
- relevant file excerpts
- expected output schema

Do not send:
- secrets
- full logs unless needed
- large unrelated code
- user PII
```

### 17.4 GLM Task Packet Format

Every GLM task should use this contract:

```markdown
# Task

One clear objective.

# Source Of Truth

Brief facts. Do not invent beyond this.

# Constraints

Hard boundaries.

# Output Format

Exact sections/JSON/table expected.

# Quality Bar

How Codex will judge the result.

# Do Not

List of forbidden mistakes.
```

### 17.5 GLM Output Schema

For implementation-adjacent tasks:

```json
{
  "summary": "...",
  "recommendations": [],
  "risks": [],
  "files_likely_affected": [],
  "tests_to_run": [],
  "open_questions": [],
  "confidence": "high|medium|low"
}
```

### 17.6 Codex Verification Loop

Codex must:

1. read GLM output
2. check against source of truth
3. mark accepted / modified / rejected
4. apply only accepted changes
5. run tests
6. record result

Example log:

```markdown
## GLM Suggestion Review

Accepted:
- Add duplicate registration guard

Modified:
- Use email-only confirmation, not email/SMS

Rejected:
- Use LINE in seminar registration

Verification:
- Unit tests passed
- E2E passed
```

### 17.7 Quality Control Rubric

Score GLM output:

1. requirement fit
2. practicality
3. language quality
4. risk control
5. completeness
6. originality/usefulness

This should become a built-in project workflow:

```bash
xpc ai review-output glm-output.md --rubric default
```

## 18. AI-Friendly Project Files

Each project should include:

```text
AGENTS.md
context.md
decisions/
  0001-ui-architecture.md
  0002-data-layer.md
ai/
  briefs/
  glm-outputs/
  reviews/
```

Purpose:

- agents know project rules
- decisions are traceable
- GLM outputs are auditable
- Codex reviews are saved
- humans can inspect the collaboration

## 19. Testing Strategy

Testing must be included early.

### 19.1 Unit Tests

Test:

- ViewModels
- validation
- services
- routing handlers
- data transformations

### 19.2 Integration Tests

Test:

- HTTP routes
- DB persistence
- auth/session
- jobs

### 19.3 E2E Tests

For web/desktop:

- use Playwright or equivalent where possible
- test user flows
- test component visibility
- test form submission
- test bridge commands

### 19.4 Golden Tests

For XUI:

- render component
- compare output DOM/snapshot
- verify accessibility attributes

## 20. Roadmap

### Phase 0: Research Spike

Goal: prove technical feasibility.

Deliverables:

- FPC CLI wrapper proof
- basic HTTP server
- minimal HTML template renderer
- WebView shell spike on Windows
- Pascal-to-JS bridge proof

### Phase 1: XCLI + Project Format

Deliverables:

- `xpc new app`
- `xpc run web`
- `xpc build`
- `xpc test`
- `xproject.toml`
- generated project skeleton

### Phase 2: XServer

Deliverables:

- routing
- middleware
- JSON
- static assets
- template rendering
- basic REST API

### Phase 3: XUI

Deliverables:

- component parser
- component renderer
- component library v0
- theme tokens
- form controls
- partial update protocol

### Phase 4: XMVVM

Deliverables:

- ViewModel base
- binding engine
- observable state
- commands
- validation
- ViewModel unit testing

### Phase 5: XDesktop

Deliverables:

- WebView shell
- native bridge
- file dialogs
- menus
- notifications
- packaging

### Phase 6: Documentation

Deliverables:

- English getting started
- Thai getting started
- tutorials
- API reference
- cookbook
- example apps

### Phase 7: IDE

Deliverables:

- project explorer
- XUI preview
- code editor
- property inspector
- binding picker
- build/test panel

## 21. MVP App

The first serious proof app should be:

```text
Mini CRM
```

Features:

- desktop mode
- web mode
- customer list
- create/edit form
- data-aware customer grid
- master-detail customer/order screen
- lookup fields
- validation shown directly in form/grid cells
- change tracking and dirty state
- SQLite
- REST API
- ViewModel validation
- HTML component UI
- tests
- packaging
- CI workflow

This proves:

- FPC backend
- XRTL
- X.Data / DataSource
- XUI
- MVVM
- business grid/table components
- master-detail binding
- desktop shell
- web server
- testing
- docs

## 22. Major Risks

### 22.1 WebView Cross-Platform Complexity

Risk:

- WebView2, WKWebView, and WebKitGTK differ.

Mitigation:

- target Windows first
- define minimal bridge
- add macOS/Linux later
- create WebView compatibility test suite

### 22.2 Template/Binding Complexity

Risk:

- HTML binding system grows into a framework monster.

Mitigation:

- start with small binding features
- avoid arbitrary JS framework complexity
- keep ViewModel as source of truth

### 22.3 Documentation Debt

Risk:

- platform becomes powerful but hard to learn like Lazarus/FPC.

Mitigation:

- docs are part of every milestone
- every API must include examples
- English and Thai docs ship together

### 22.4 AI Workflow Drift

Risk:

- Codex does too much or GLM outputs are unverified.

Mitigation:

- use saved GLM task packets
- require Codex review logs
- run tests before accepting changes

### 22.5 Native Feel Expectations

Risk:

- users expect true native widgets, but HTML UI is WebView-based.

Mitigation:

- be honest: native shell + web UI
- provide native bridge for menus/dialogs/notifications
- make UI polished and fast

### 22.6 Data Binding Complexity

Risk:

- data binding becomes too magical, fragile, or hard to debug.
- master-detail, validation, dirty state, paging, and virtual grids can interact in complicated ways.

Mitigation:

- start with explicit DataSource APIs
- make binding state inspectable in dev tools
- provide strong diagnostics for missing fields, invalid bindings, and broken master-detail links
- keep ViewModel and DataSource testable without UI
- ship examples for every business data pattern
- avoid hidden global state
- document the mental model clearly in English and Thai

## 23. Open Design Questions

1. Should templates use standard Custom Elements syntax as much as possible?
2. Should component files use `.xui.html`, `.html`, or `.xhtml`?
3. How strict should the template parser be?
4. Should JS be optional or hidden entirely?
5. How much client-side interactivity should be allowed?
6. Should the default update model be server-rendered partials, client-side state sync, or hybrid?
7. What is the first target OS?
8. Should the IDE itself be built with XPascal once the platform is mature?
9. Should `X.Data` be inspired more by Delphi `TDataSet/TDataSource`, Lazarus data controls, or a newer CollectionView model?
10. Should master-detail binding live in DataSource, ViewModel, or template declarations?
11. How much grid behavior should be built into `x-data-grid` versus delegated to plugins?
12. Should data-aware components support offline/local-first operation in the first major version?

## 24. Initial Recommendation

Start with:

```text
FreePascal + XCLI + XServer + X.Data + HTML component templates
```

Then add:

```text
XMVVM + data-aware components + XDesktop shell
```

Do not build the IDE first.

Do not chase Delphi/Lazarus compatibility.

Do not build a native widget framework first.

Do not clone Electron or React Native.

Build a small, coherent, documented platform that proves:

```text
Pascal can feel modern again.
```

## 25. One-Sentence Positioning

XPascal is a modern FreePascal app platform for building desktop, web, and server software with MVVM, HTML components, data-aware business components, batteries-included libraries, excellent bilingual documentation, and workflows designed for CLI, CI/CD, and AI agents from day one.
