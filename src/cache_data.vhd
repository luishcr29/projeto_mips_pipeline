-- ============================================================================
-- CACHE DE DADOS - Direct-Mapped com Write-Through
-- ============================================================================
-- Parâmetros configuráveis:
-- - CACHE_SIZE = 16 linhas
-- - BLOCK_SIZE = 1 palavra (32 bits)
-- - Política de escrita: Write-Through (escreve no cache E na memória)
-- - Política de substituição: Direct-Mapped
-- ============================================================================

LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.NUMERIC_STD.ALL;

ENTITY cache_data IS
    GENERIC (
        CACHE_LINES : INTEGER := 16;
        ADDR_WIDTH  : INTEGER := 8     -- Bits de endereço para dmem
    );
    PORT (
        clk       : IN  STD_LOGIC;
        reset     : IN  STD_LOGIC;
        -- Interface com o processador
        we        : IN  STD_LOGIC;     -- Write enable
        addr      : IN  STD_LOGIC_VECTOR(31 DOWNTO 0);
        data_in   : IN  STD_LOGIC_VECTOR(31 DOWNTO 0);
        data_out  : OUT STD_LOGIC_VECTOR(31 DOWNTO 0);
        stall     : OUT STD_LOGIC;
        -- Interface com a memória principal (dmem)
        mem_we    : OUT STD_LOGIC;
        mem_addr  : OUT STD_LOGIC_VECTOR(ADDR_WIDTH-1 DOWNTO 0);
        mem_din   : OUT STD_LOGIC_VECTOR(31 DOWNTO 0);
        mem_dout  : IN  STD_LOGIC_VECTOR(31 DOWNTO 0);
        -- Estatísticas
        hit_count : OUT INTEGER;
        miss_count: OUT INTEGER
    );
END cache_data;

ARCHITECTURE behave OF cache_data IS
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
    
    -- Contadores
    SIGNAL hits  : INTEGER := 0;
    SIGNAL misses: INTEGER := 0;
    
    -- Máquina de estados
    TYPE state_type IS (IDLE, FETCH_MEM, WRITE_MEM);
    SIGNAL state : state_type := IDLE;
    
BEGIN
    -- Extração do índice e tag
    index <= to_integer(unsigned(addr(5 DOWNTO 2))) MOD CACHE_LINES;
    tag   <= addr;
    
    -- Lógica de hit/miss
    hit <= '1' WHEN (cache(index).valid = '1' AND cache(index).tag = tag) ELSE '0';
    miss <= NOT hit;
    
    -- Processo principal
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
            mem_we <= '0';
            
        ELSIF rising_edge(clk) THEN
            CASE state IS
                WHEN IDLE =>
                    mem_we <= '0';
                    
                    IF we = '1' THEN
                        -- OPERAÇÃO DE ESCRITA (Write-Through)
                        -- Escreve no cache (se hit) E na memória sempre
                        IF hit = '1' THEN
                            cache(index).data <= data_in;
                            hits <= hits + 1;
                        ELSE
                            misses <= misses + 1;
                            -- Em miss, atualiza o cache também
                            cache(index).valid <= '1';
                            cache(index).tag   <= tag;
                            cache(index).data  <= data_in;
                        END IF;
                        
                        -- Escreve na memória principal (Write-Through)
                        mem_we <= '1';
                        mem_addr <= addr(ADDR_WIDTH-1 DOWNTO 0);
                        mem_din <= data_in;
                        stall <= '0';
                        
                    ELSE
                        -- OPERAÇÃO DE LEITURA
                        IF hit = '1' THEN
                            -- Cache HIT
                            data_out <= cache(index).data;
                            hits <= hits + 1;
                            stall <= '0';
                        ELSE
                            -- Cache MISS
                            misses <= misses + 1;
                            stall <= '1';
                            state <= FETCH_MEM;
                            mem_addr <= addr(ADDR_WIDTH-1 DOWNTO 0);
                        END IF;
                    END IF;
                    
                WHEN FETCH_MEM =>
                    -- Busca dado da memória
                    cache(index).valid <= '1';
                    cache(index).tag   <= tag;
                    cache(index).data  <= mem_dout;
                    data_out <= mem_dout;
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
-- POLÍTICA DE ESCRITA: WRITE-THROUGH
-- - Quando há uma escrita (we='1'):
--   * Atualiza o cache (se HIT) ou cria nova entrada (se MISS)
--   * SEMPRE escreve na memória principal também
--   * Vantagem: Dados sempre consistentes entre cache e memória
--   * Desvantagem: Mais acessos à memória principal
--
-- POLÍTICA DE LEITURA:
-- - HIT: Retorna dado do cache imediatamente (1 ciclo)
-- - MISS: Busca da memória, atualiza cache, retorna dado (2 ciclos)
--
-- MAPEAMENTO:
-- - addr[31:6] = TAG
-- - addr[5:2]  = INDEX (seleciona uma das 16 linhas)
-- - addr[1:0]  = byte offset
--
-- ALTERNATIVA (Write-Back):
-- Se quiser implementar Write-Back (mais eficiente):
-- - Adicionar bit "dirty" em cada linha
-- - Só escrever na memória quando a linha for substituída
-- - Requer mais lógica de controle
--
-- ============================================================================