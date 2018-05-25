

// export as instance
declare let instance:Cache
export = instance

interface Cache {
    
    /**
    * Armazena um valor em cache.
    * @param CHAVE A chave aonde o valor será armazenado.
    * @param VALOR O valor a ser armazenado.
    * @param TTL Tempo em segundos que o valor deverá permanecer no cache.
    */
    set(CHAVE :string, VALOR: any, TTL?: number): Cache;

    /**
     * Resgata um valor em cache.
     * @param CHAVE A chave aonde está armazenado o valor.
     */
    get(CHAVE): any;
}