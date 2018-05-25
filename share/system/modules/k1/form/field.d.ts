export declare class FormField {
    label: any;
    name: any;
    type: string;
    value: any;
    required: boolean;
    tag: string;
    class: string;
    wrapper: {
        tag: string;
        class: string;
    };
    errors: any[];
    constructor(params?: {});
    setValue(value: any): boolean;
    validate(value: any): boolean;
    isValid(): boolean;
    render(): any;
    renderElement(): any;
    fillElement(element: any): void;
    renderError(element: any): void;
    findElement(rootElement: any): any;
}
