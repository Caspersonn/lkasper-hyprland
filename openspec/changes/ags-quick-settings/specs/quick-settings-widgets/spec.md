## ADDED Requirements

### Requirement: Tile widget
The Tile component in `ags/windows/quick-settings/widgets/tile.tsx` SHALL be a GObject-registered GTK Box widget providing a toggleable quick-settings control with icon, title, description, and on/off state.

#### Scenario: Toggle tile via icon click
- **GIVEN** a Tile with state=false
- **WHEN** the user clicks the icon area
- **THEN** state becomes true, 'enabled' CSS class is added, 'toggled' signal emitted with true, 'enabled' signal emitted

#### Scenario: Disable tile via icon click
- **GIVEN** a Tile with state=true
- **WHEN** the user clicks the icon area
- **THEN** state becomes false, 'enabled' CSS class is removed, 'toggled' signal emitted with false, 'disabled' signal emitted

#### Scenario: Enable is idempotent
- **GIVEN** a Tile with state=true
- **WHEN** enable() is called
- **THEN** no state change occurs and no signals are emitted

#### Scenario: Disable is idempotent
- **GIVEN** a Tile with state=false
- **WHEN** disable() is called
- **THEN** no state change occurs and no signals are emitted

#### Scenario: Toggle on content click when toggleOnClick is true
- **GIVEN** a Tile with toggleOnClick=true and state=false
- **WHEN** the user clicks the content area (outside the icon)
- **THEN** the clicked signal fires and the tile toggles to enabled

#### Scenario: Content click emits clicked signal when toggleOnClick is false
- **GIVEN** a Tile with toggleOnClick=false (default)
- **WHEN** the user clicks the content area
- **THEN** the 'clicked' signal fires but state is unchanged

#### Scenario: Arrow shown when hasArrow is true
- **GIVEN** a Tile with hasArrow=true
- **WHEN** the tile is rendered
- **THEN** a go-next arrow icon SHALL be visible at the end of the tile

#### Scenario: Description hidden when empty
- **GIVEN** a Tile with description=""
- **WHEN** the tile is rendered
- **THEN** the description label SHALL be hidden

#### Scenario: Initial state applies CSS class
- **GIVEN** a Tile constructed with state=true
- **WHEN** the constructor completes
- **THEN** the 'enabled' CSS class is present on the widget

### Requirement: Tiles container
The tiles container SHALL render tiles in a 2-column FlowBox grid with a Pages instance for tile detail pages.

#### Scenario: Render tiles in grid
- **GIVEN** the control center is open
- **WHEN** the tiles container is rendered
- **THEN** tiles SHALL be displayed in a 2-column horizontal FlowBox with equal sizing

### Requirement: Page class
The Page class in `ags/windows/quick-settings/widgets/page.tsx` SHALL represent a navigable detail page with header, scrollable content, and optional action buttons.

#### Scenario: Create page widget
- **GIVEN** a Page instance with id, title, and content
- **WHEN** create() is called
- **THEN** a Gtk.Box is returned containing header, content area, and optional bottom-buttons section

#### Scenario: Page with description
- **GIVEN** a Page with a non-null description
- **WHEN** the page is rendered
- **THEN** the description label is visible below the title

#### Scenario: Page without description
- **GIVEN** a Page with null description
- **WHEN** the page is rendered
- **THEN** the description label is hidden

#### Scenario: Page with header buttons
- **GIVEN** a Page with headerButtons array containing entries
- **WHEN** the page is rendered
- **THEN** header button row is visible with each button rendered

#### Scenario: Page with bottom buttons
- **GIVEN** a Page with bottomButtons array containing entries
- **WHEN** the page is rendered
- **THEN** a separator and bottom button section are visible, each rendered as a PageButton

### Requirement: Pages manager
The Pages manager in `ags/windows/quick-settings/widgets/pages.tsx` SHALL manage opening, closing, and toggling of detail pages using Gtk.Revealer slide-down animation, allowing only one page open at a time.

#### Scenario: Open a page
- **GIVEN** no page is currently open
- **WHEN** pages.open(newPage) is called
- **THEN** a Gtk.Revealer is prepended containing the page widget, revealChild is set to true

#### Scenario: Close the current page
- **GIVEN** a page is currently open
- **WHEN** pages.close() is called
- **THEN** the Revealer slides closed, the page's actionClosed callback fires, and the page widget is removed after the transition duration

#### Scenario: Toggle to a different page
- **GIVEN** page A is open
- **WHEN** pages.toggle(pageB) is called
- **THEN** page A is closed and page B is opened

#### Scenario: Toggle same page closes it
- **GIVEN** page A is open
- **WHEN** pages.toggle(pageA) is called
- **THEN** page A is closed and no new page is opened

### Requirement: PageButton helper
The PageButton component SHALL render a styled button with optional icon, title, description, end widget, and extra buttons, used for list items within Pages.

#### Scenario: Render PageButton with icon and description
- **GIVEN** a PageButton with icon, title, and description set
- **WHEN** the component is rendered
- **THEN** the icon, title, and description are all visible

#### Scenario: Render PageButton without optional elements
- **GIVEN** a PageButton with only title set
- **WHEN** the component is rendered
- **THEN** icon, description, endWidget, and extraButtons sections are hidden

#### Scenario: Click PageButton
- **GIVEN** a PageButton with an actionClicked callback
- **WHEN** the button is clicked
- **THEN** the actionClicked callback is invoked
