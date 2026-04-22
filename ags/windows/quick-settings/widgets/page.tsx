import { Gtk } from "ags/gtk4"
import { Accessor, createBinding, createRoot, For, Node } from "ags"
import { property, register } from "ags/gobject"
import GObject from "gi://GObject"
import Pango from "gi://Pango"

export type HeaderButton = {
    label?: string | Accessor<string>
    icon: string | Accessor<string>
    tooltipText?: string | Accessor<string>
    actionClicked?: () => void
}

export type BottomButton = {
    title: string | Accessor<string>
    description?: string | Accessor<string>
    tooltipText?: string | Accessor<string>
    actionClicked?: () => void
}

@register({ GTypeName: "LkhPage" })
export class Page extends GObject.Object {
    readonly #id: string
    readonly #create: () => Node

    public readonly actionClosed?: () => void
    public readonly actionOpen?: () => void
    public get id() { return this.#id }

    @property(String)
    title: string = ""

    @property(String)
    description: string | null = null

    @property(Number)
    spacing: number = 4

    headerButtons: HeaderButton[] = []
    bottomButtons: BottomButton[] = []

    constructor(props: {
        id: string
        title: string
        description?: string
        headerButtons?: HeaderButton[] | Accessor<HeaderButton[]>
        bottomButtons?: BottomButton[]
        spacing?: number
        content: () => Node
        actionOpen?: () => void
        actionClosed?: () => void
    }) {
        super()

        this.#id = props.id
        this.#create = props.content
        this.title = props.title
        this.actionClosed = props.actionClosed
        this.actionOpen = props.actionOpen

        if (props.description != null) this.description = props.description
        if (props.spacing != null) this.spacing = props.spacing
        if (props.headerButtons != null) this.headerButtons = props.headerButtons as HeaderButton[]
        if (props.bottomButtons != null) this.bottomButtons = props.bottomButtons
    }

    public create(): Gtk.Box {
        return createRoot((dispose) =>
            <Gtk.Box hexpand class={`page container ${this.#id ?? ""}`}
                orientation={Gtk.Orientation.VERTICAL}
                onDestroy={() => dispose()}>

                {/* Header */}
                <Gtk.Box class="header" orientation={Gtk.Orientation.VERTICAL}>
                    <Gtk.Box class="top" hexpand>
                        <Gtk.Box orientation={Gtk.Orientation.VERTICAL} hexpand>
                            <Gtk.Label class="title" label={createBinding(this, "title")}
                                xalign={0} ellipsize={Pango.EllipsizeMode.END} />
                            <Gtk.Label class="description"
                                label={createBinding(this, "description").as((d: string | null) => d ?? "")}
                                xalign={0} ellipsize={Pango.EllipsizeMode.END}
                                visible={createBinding(this, "description").as((d: string | null) => d != null && d !== "")} />
                        </Gtk.Box>
                        {this.headerButtons.length > 0 &&
                            <Gtk.Box class="button-row" hexpand={false}>
                                {(this.headerButtons as HeaderButton[]).map((btn: HeaderButton) =>
                                    <Gtk.Button class="header-button"
                                        iconName={btn.icon}
                                        label={btn.label}
                                        tooltipText={btn.tooltipText}
                                        onClicked={() => btn.actionClicked?.()} />
                                )}
                            </Gtk.Box>
                        }
                    </Gtk.Box>
                </Gtk.Box>

                {/* Content */}
                <Gtk.Box class="content" hexpand={false}
                    orientation={Gtk.Orientation.VERTICAL}
                    spacing={createBinding(this, "spacing")}>
                    {this.#create()}
                </Gtk.Box>

                {/* Bottom buttons */}
                {this.bottomButtons.length > 0 && <>
                    <Gtk.Separator orientation={Gtk.Orientation.HORIZONTAL} />
                    <Gtk.Box class="bottom-buttons" orientation={Gtk.Orientation.VERTICAL} spacing={2}>
                        {this.bottomButtons.map((btn: BottomButton) =>
                            <PageButton
                                title={btn.title}
                                description={btn.description}
                                tooltipText={btn.tooltipText}
                                actionClicked={() => btn.actionClicked?.()} />
                        )}
                    </Gtk.Box>
                </>}
            </Gtk.Box> as Gtk.Box
        )
    }

    public static getContent(pageWidget: Gtk.Box): Gtk.Box {
        return pageWidget.get_first_child()!.get_next_sibling()! as Gtk.Box
    }
}

export function PageButton(props: {
    class?: string | Accessor<string>
    icon?: string | Accessor<string>
    title: string | Accessor<string>
    endWidget?: Node
    description?: string | Accessor<string>
    extraButtons?: Node
    maxWidthChars?: number
    actionClicked?: (self: Gtk.Button) => void
    tooltipText?: string | Accessor<string>
}): Gtk.Box {
    return <Gtk.Box class="page-button">
        <Gtk.Button onClicked={props.actionClicked} class={props.class} hexpand
            tooltipText={props.tooltipText}>
            <Gtk.Box class="container" hexpand>
                {props.icon &&
                    <Gtk.Image iconName={props.icon}
                        visible={typeof props.icon === "string" ? props.icon !== "" : true} />
                }
                <Gtk.Box orientation={Gtk.Orientation.VERTICAL} hexpand vexpand={false}>
                    <Gtk.Label class="title" xalign={0} tooltipText={props.title}
                        ellipsize={Pango.EllipsizeMode.END} label={props.title}
                        maxWidthChars={props.maxWidthChars ?? 28} />
                    {props.description &&
                        <Gtk.Label class="description" xalign={0}
                            label={props.description} ellipsize={Pango.EllipsizeMode.END}
                            tooltipText={props.description} />
                    }
                </Gtk.Box>
                {props.endWidget &&
                    <Gtk.Box halign={Gtk.Align.END}>{props.endWidget}</Gtk.Box>
                }
            </Gtk.Box>
        </Gtk.Button>
        {props.extraButtons &&
            <Gtk.Box class="extra-buttons">{props.extraButtons}</Gtk.Box>
        }
    </Gtk.Box> as Gtk.Box
}
