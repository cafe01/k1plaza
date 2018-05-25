import { FormField } from "k1/form/field";
export declare class FileField extends FormField {
    type: string;
    maxSize: number;
    constructor(config: any);
    validate(value: any): boolean;
}
