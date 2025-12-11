-- ============================================================================
-- CACHE DE INSTRUÇÕES - Direct-Mapped (CORRIGIDO)
-- ============================================================================
-- Correção: Geração do sinal 'stall' movida para lógica combinacional
-- para garantir paragem imediata do processador em caso de Miss.
-- ============================================================================

LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.NUMERIC_STD.ALL;

ENTITY cache_instr IS
    GENERIC (
        CACHE_LINES : INTEGER := 16;  -- Número de linhas do cache
        ADDR_WIDTH  : INTEGER := 6     -- Bits de endereço para imem
    );
    PORT (
        clk       : IN  STD_LOGIC;
        reset     : IN  STD_LOGIC;
        -- Interface com o processador
        addr      : IN  STD_LOGIC_VECTOR(31 DOWNTO 0);
        instr_out : OUT STD_LOGIC_VECTOR(31 DOWNTO 0);
        stall     : OUT STD_LOGIC;     -- Sinal de stall para o processador
        -- Interface com a memória principal (imem)
        mem_addr  : OUT STD_LOGIC_VECTOR(ADDR_WIDTH-1 DOWNTO 0);
        mem_data  : IN  STD_LOGIC_VECTOR(31 DOWNTO 0);
        -- Estatísticas
        hit_count : OUT INTEGER;
        miss_count: OUT INTEGER
    );
END cache_instr;

ARCHITECTURE behave OF cache_instr IS
    -- Estrutura de uma linha do cache
    TYPE cache_line IS RECORD
        valid : STD_LOGIC;
        tag   : STD_LOGIC_VECTOR(31 DOWNTO 0);
        data  : STD_LOGIC_VECTOR(31 DOWNTO 0);
    END RECORD;

    TYPE cache_array IS ARRAY (0 TO CACHE_LINES-1) OF cache_line;
    SIGNAL cache : cache_array;

    -- Sinais internos
    SIGNAL index : INTEGER RANGE 0 TO CACHE_LINES-1;
    SIGNAL tag   : STD_LOGIC_VECTOR(31 DOWNTO 0);
    SIGNAL hit   : STD_LOGIC;
    
    -- Contadores de estatísticas
    SIGNAL hits  : INTEGER := 0;
    SIGNAL misses: INTEGER := 0;
    
    -- Máquina de estados para tratamento de miss
    TYPE state_type IS (IDLE, FETCH_MEM);
    SIGNAL state : state_type := IDLE;
    
BEGIN
    -- Extração do índice e tag do endereço
    -- Assumindo mapeamento direto: tag | index | offset
    index <= to_integer(unsigned(addr(5 DOWNTO 2))) MOD CACHE_LINES;
    tag   <= addr;
    
    -- Lógica de hit/miss (Combinacional)
    hit <= '1' WHEN (cache(index).valid = '1' AND cache(index).tag = tag) ELSE '0';
    
    -- ========================================================================
    -- CORREÇÃO CRÍTICA: Lógica de Stall (Combinacional)
    -- ========================================================================
    -- O stall deve ser '1' IMEDIATAMENTE se:
    -- 1. Estamos buscando da memória (state = FETCH_MEM) OU
    -- 2. Acabamos de detectar um MISS no estado IDLE
    stall <= '1' WHEN (state = FETCH_MEM) OR (state = IDLE AND hit = '0') ELSE '0';
    
    -- Processo principal do cache (Síncrono)
    PROCESS(clk, reset)
    BEGIN
        IF reset = '1' THEN
            -- Inicializa o cache
            FOR i IN 0 TO CACHE_LINES-1 LOOP
                cache(i).valid <= '0';
                cache(i).tag   <= (OTHERS => '0');
                cache(i).data  <= (OTHERS => '0');
            END LOOP;
            hits <= 0;
            misses <= 0;
            state <= IDLE;
            -- stall não é mais atribuído aqui
            
        ELSIF rising_edge(clk) THEN
            CASE state IS
                WHEN IDLE =>
                    IF hit = '1' THEN
                        -- Cache HIT
                        instr_out <= cache(index).data;
                        hits <= hits + 1;
                        -- stall controlado combinacionalmente (será '0')
                    ELSE
                        -- Cache MISS
                        misses <= misses + 1;
                        state <= FETCH_MEM;
                        -- Endereço para memória: bits superiores (ignora offset byte)
                        mem_addr <= addr(ADDR_WIDTH+1 DOWNTO 2);
                        -- stall controlado combinacionalmente (será '1')
                    END IF;
                    
                WHEN FETCH_MEM =>
                    -- Recebe dado da memória e atualiza cache
                    cache(index).valid <= '1';
                    cache(index).tag   <= tag;
                    cache(index).data  <= mem_data;
                    
                    instr_out <= mem_data; -- Já entrega o dado
                    state <= IDLE;
                    -- No próximo ciclo, state será IDLE e hit será '1', liberando o stall
                    
                WHEN OTHERS =>
                    state <= IDLE;
            END CASE;
        END IF;
    END PROCESS;
    
    -- Saída das estatísticas
    hit_count <= hits;
    miss_count <= misses;
    
END behave;