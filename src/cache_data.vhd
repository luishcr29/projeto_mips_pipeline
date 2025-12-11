-- ============================================================================
-- CACHE DE DADOS - Direct-Mapped com Write-Through (CORRIGIDO)
-- ============================================================================
-- Correção: Stall combinacional para garantir parada em Leitura/Miss.
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
    
    -- Contadores
    SIGNAL hits  : INTEGER := 0;
    SIGNAL misses: INTEGER := 0;
    
    -- Máquina de estados
    TYPE state_type IS (IDLE, FETCH_MEM);
    SIGNAL state : state_type := IDLE;
    
BEGIN
    -- Extração do índice e tag
    index <= to_integer(unsigned(addr(5 DOWNTO 2))) MOD CACHE_LINES;
    tag   <= addr;
    
    -- Lógica de hit/miss
    hit <= '1' WHEN (cache(index).valid = '1' AND cache(index).tag = tag) ELSE '0';
    
    -- ========================================================================
    -- CORREÇÃO CRÍTICA: Lógica de Stall (Combinacional)
    -- ========================================================================
    -- Stall acontece apenas em LEITURA (we='0') que causa MISS, 
    -- ou enquanto espera a memória (FETCH_MEM).
    -- Escritas (we='1') não causam stall nesta implementação Write-Through.
    stall <= '1' WHEN (state = FETCH_MEM) OR 
                      (state = IDLE AND we = '0' AND hit = '0') 
                 ELSE '0';
    
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
            mem_we <= '0';
            
        ELSIF rising_edge(clk) THEN
            CASE state IS
                WHEN IDLE =>
                    mem_we <= '0';
                    
                    IF we = '1' THEN
                        -- ====================================================
                        -- ESCRITA (Write-Through)
                        -- ====================================================
                        -- Atualiza cache se HIT (ou se policy for Write-Allocate, aqui simplificado)
                        IF hit = '1' THEN
                            cache(index).data <= data_in;
                            hits <= hits + 1;
                        ELSE
                            misses <= misses + 1;
                            -- Opcional: Write Allocate (traz para o cache no miss de escrita)
                            cache(index).valid <= '1';
                            cache(index).tag   <= tag;
                            cache(index).data  <= data_in;
                        END IF;
                        
                        -- Sempre escreve na memória
                        mem_we <= '1';
                        mem_addr <= addr(ADDR_WIDTH-1 DOWNTO 0);
                        mem_din <= data_in;
                        
                    ELSE
                        -- ====================================================
                        -- LEITURA
                        -- ====================================================
                        IF hit = '1' THEN
                            -- Cache HIT
                            data_out <= cache(index).data;
                            hits <= hits + 1;
                        ELSE
                            -- Cache MISS
                            misses <= misses + 1;
                            state <= FETCH_MEM;
                            mem_addr <= addr(ADDR_WIDTH-1 DOWNTO 0);
                        END IF;
                    END IF;
                    
                WHEN FETCH_MEM =>
                    -- Busca dado da memória e completa a LEITURA
                    cache(index).valid <= '1';
                    cache(index).tag   <= tag;
                    cache(index).data  <= mem_dout;
                    
                    data_out <= mem_dout;
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