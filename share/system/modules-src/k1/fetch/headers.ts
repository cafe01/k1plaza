export class Headers {

    headers: object = null
        
    constructor (init:object = {}) {
       
        this.headers = { ...init }
    }

    append(key:string, value:string) {

        if (this.headers.hasOwnProperty(key)) {
            this.headers[key] = `${this.headers[key]}, ${value}`
        }
        else {
            this.headers[key] = value
        }        
    }

    set(key:string, value:string) {
        this.headers[key] = value
    }

    get(key) :string {
        return this.headers[key]
    }

    delete(key) {
        delete this.headers[key]
    }

    has(key) :boolean {
        return this.headers.hasOwnProperty(key)
    }

    keys() {
        return Object.keys(this.headers)
    }

    toObject() {
        return { ...this.headers }
    }

}