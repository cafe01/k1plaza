import { FormField } from "./form/field";
import { TextField } from "./form/field/text";
import { TextAreaField } from "./form/field/textarea";
import { EmailField } from "./form/field/email";
import { HiddenField } from "./form/field/hidden";
import { SubmitField } from "./form/field/submit";
import { FileField } from "./form/field/file";
import { RecaptchaField } from "./form/field/recaptcha";
declare class Form {
    name: any;
    fields: FormField[];
    isProcessed: boolean;
    isValid: boolean;
    constructor(config?: any);
    action(): void;
    getField(name: string): FormField;
    process(values: object): {
        success: boolean;
        fields: {};
        errors?: undefined;
    } | {
        success: boolean;
        errors: any[];
        fields?: undefined;
    };
    render(element: any): object;
}
export { Form, FormField, TextField, TextAreaField, EmailField, SubmitField, HiddenField, FileField, RecaptchaField };
