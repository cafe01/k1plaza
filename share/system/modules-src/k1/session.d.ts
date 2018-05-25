

// export as instance
declare let instance:Session
export = instance

interface Session {
    
    /**
    * Armazena um valor na sessão. (via cookie)
    * Certifique-se que o tamanho máximo não exceda 4096 bytes! (limite do cookie)
    * 
    * @param CHAVE A chave aonde o valor será armazenado.
    * @param VALOR O valor a ser armazenado.
    */
    set(CHAVE :string, VALOR: any, TTL?: number): Session;

    /**
     * Resgata um valor da sessão.
     * @param CHAVE A chave aonde está armazenado o valor.
     */
    get(CHAVE): any;
}