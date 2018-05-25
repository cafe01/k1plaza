

// export as instance
declare let instance:Flash
export = instance

interface Flash {
    
    /**
    * Armazena um valor em Flash.
    * @param CHAVE A chave aonde o valor será armazenado.
    * @param VALOR O valor a ser armazenado.
    */
    set(CHAVE :string, VALOR: any): Flash;

    /**
     * Resgata um valor em Flash.
     * @param CHAVE A chave aonde está armazenado o valor.
     */
    get(CHAVE): any;
}