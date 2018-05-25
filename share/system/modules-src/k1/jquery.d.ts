interface jQuery {
    add_class(className :string): jQuery;
    remove_class(className :string): jQuery;
    append(stuff :any): jQuery;
    children(selector?: string): jQuery;
    remove_attr(name: string): jQuery;
    attr(name: string): string | undefined;
    attr(name: string, value: string): jQuery;
    text(text: string): jQuery;
    insert_after(element: jQuery): jQuery;
    insert_after(selector: string): jQuery;
}

export function jQuery(htmlOrSelector: string): jQuery;
