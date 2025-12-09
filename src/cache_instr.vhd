-- ============================================================================
-- CACHE DE INSTRUÇÕES - Direct-Mapped
-- ============================================================================
-- Parâmetros configuráveis:
-- - CACHE_SIZE = 16 linhas (pode ser ajustado)
-- - BLOCK_SIZE = 1 palavra (32 bits)
-- - Política de substituição: Direct-Mapped (sem escolha)
-- - Write policy: N/A (cache de instruções é read-only)
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
    SIGNAL miss  : STD_LOGIC;
    
    -- Contadores de estatísticas
    SIGNAL hits  : INTEGER := 0;
    SIGNAL misses: INTEGER := 0;
    
    -- Máquina de estados para tratamento de miss
    TYPE state_type IS (IDLE, FETCH_MEM);
    SIGNAL state : state_type := IDLE;
    
BEGIN
    -- Extração do índice e tag do endereço
    index <= to_integer(unsigned(addr(5 DOWNTO 2))) MOD CACHE_LINES;
    tag   <= addr;
    
    -- Lógica de hit/miss
    hit <= '1' WHEN (cache(index).valid = '1' AND cache(index).tag = tag) ELSE '0';
    miss <= NOT hit;
    
    -- Processo principal do cache
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
            stall <= '0';
            
        ELSIF rising_edge(clk) THEN
            CASE state IS
                WHEN IDLE =>
                    IF hit = '1' THEN
                        -- Cache HIT
                        instr_out <= cache(index).data;
                        hits <= hits + 1;
                        stall <= '0';
                    ELSE
                        -- Cache MISS - precisa buscar da memória
                        misses <= misses + 1;
                        stall <= '1';
                        state <= FETCH_MEM;
                        mem_addr <= addr(ADDR_WIDTH+1 DOWNTO 2);
                    END IF;
                    
                WHEN FETCH_MEM =>
                    -- Recebe dado da memória e atualiza cache
                    cache(index).valid <= '1';
                    cache(index).tag   <= tag;
                    cache(index).data  <= mem_data;
                    instr_out <= mem_data;
                    stall <= '0';
                    state <= IDLE;
                    
                WHEN OTHERS =>
                    state <= IDLE;
            END CASE;
        END IF;
    END PROCESS;
    
    -- Saída das estatísticas
    hit_count <= hits;
    miss_count <= misses;
    
END behave;

-- ============================================================================
-- DOCUMENTAÇÃO
-- ============================================================================
--
-- FUNCIONAMENTO:
-- 1. Quando o processador requisita uma instrução, o cache verifica se ela
--    está presente (HIT) ou não (MISS)
-- 2. Em caso de HIT, a instrução é retornada imediatamente (1 ciclo)
-- 3. Em caso de MISS:
--    - O cache envia o sinal STALL='1' para parar o processador
--    - Busca a instrução da memória principal (1 ciclo extra)
--    - Atualiza a linha do cache
--    - Retorna a instrução e libera o processador (STALL='0')
--
-- MAPEAMENTO DE ENDEREÇOS:
-- - addr[31:6] = TAG (identifica qual bloco da memória)
-- - addr[5:2]  = INDEX (seleciona linha do cache)
-- - addr[1:0]  = byte offset (sempre "00" para instruções alinhadas)
--
-- ESTATÍSTICAS:
-- - hit_count: Total de acessos que encontraram no cache
-- - miss_count: Total de acessos que precisaram buscar na memória
-- - Hit Rate = hits / (hits + misses)
--
-- PARÂMETROS CONFIGURÁVEIS:
-- - CACHE_LINES: Número de linhas (16 = 16 instruções no cache)
-- - Pode ser aumentado para 32, 64, etc. para melhorar hit rate
--
-- ============================================================================