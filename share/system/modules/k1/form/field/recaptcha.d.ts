import { FormField } from "k1/form/field";
export declare class RecaptchaField extends FormField {
    key: null;
    secret: null;
    constructor(config: any);
    renderElement(): any;
    fillElement(element: any): void;
    findElement(rootElement: any): any;
}
