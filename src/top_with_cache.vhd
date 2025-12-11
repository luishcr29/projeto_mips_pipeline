-- ============================================================================
-- TOP-LEVEL COM CACHE DE INSTRUÇÕES E DADOS
-- ============================================================================
-- Esta versão inclui:
-- - Cache de instruções (16 linhas)
-- - Cache de dados (16 linhas)
-- - Estatísticas de hit/miss
-- ============================================================================

LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.NUMERIC_STD.ALL;

ENTITY top_with_cache IS
    PORT (
        clk, reset : IN STD_LOGIC;
        writedata, dataadr : BUFFER STD_LOGIC_VECTOR(31 DOWNTO 0);
        memwrite : BUFFER STD_LOGIC;
        -- Estatísticas do cache
        icache_hits, icache_misses : OUT INTEGER;
        dcache_hits, dcache_misses : OUT INTEGER
    );
END top_with_cache;

ARCHITECTURE arch OF top_with_cache IS
    -- Componente MIPS
    COMPONENT mips 
        PORT (
            clk, reset : IN STD_LOGIC;
            pc : OUT STD_LOGIC_VECTOR(31 DOWNTO 0);
            instr : IN STD_LOGIC_VECTOR(31 DOWNTO 0);
            memwrite : OUT STD_LOGIC;
            aluout, writedata : OUT STD_LOGIC_VECTOR(31 DOWNTO 0);
            readdata : IN STD_LOGIC_VECTOR(31 DOWNTO 0)
        );
    END COMPONENT;
    
    -- Componente Cache de Instruções
    COMPONENT cache_instr
        GENERIC (
            CACHE_LINES : INTEGER := 16;
            ADDR_WIDTH  : INTEGER := 6
        );
        PORT (
            clk, reset : IN STD_LOGIC;
            addr : IN STD_LOGIC_VECTOR(31 DOWNTO 0);
            instr_out : OUT STD_LOGIC_VECTOR(31 DOWNTO 0);
            stall : OUT STD_LOGIC;
            mem_addr : OUT STD_LOGIC_VECTOR(5 DOWNTO 0);
            mem_data : IN STD_LOGIC_VECTOR(31 DOWNTO 0);
            hit_count, miss_count : OUT INTEGER
        );
    END COMPONENT;
    
    -- Componente Cache de Dados
    COMPONENT cache_data
        GENERIC (
            CACHE_LINES : INTEGER := 16;
            ADDR_WIDTH  : INTEGER := 8
        );
        PORT (
            clk, reset : IN STD_LOGIC;
            we : IN STD_LOGIC;
            addr : IN STD_LOGIC_VECTOR(31 DOWNTO 0);
            data_in : IN STD_LOGIC_VECTOR(31 DOWNTO 0);
            data_out : OUT STD_LOGIC_VECTOR(31 DOWNTO 0);
            stall : OUT STD_LOGIC;
            mem_we : OUT STD_LOGIC;
            mem_addr : OUT STD_LOGIC_VECTOR(7 DOWNTO 0);
            mem_din : OUT STD_LOGIC_VECTOR(31 DOWNTO 0);
            mem_dout : IN STD_LOGIC_VECTOR(31 DOWNTO 0);
            hit_count, miss_count : OUT INTEGER
        );
    END COMPONENT;
    
    -- Componente IMEM (Memória de Instruções)
    COMPONENT imem
        PORT (
            a : IN STD_LOGIC_VECTOR(5 DOWNTO 0);
            rd : OUT STD_LOGIC_VECTOR(31 DOWNTO 0)
        );
    END COMPONENT;
    
    -- Componente DMEM (Memória de Dados)
    COMPONENT dmem
        PORT (
            clk, we : IN STD_LOGIC;
            a, wd : IN STD_LOGIC_VECTOR(31 DOWNTO 0);
            rd : OUT STD_LOGIC_VECTOR(31 DOWNTO 0)
        );
    END COMPONENT;
    
    -- Sinais internos
    SIGNAL pc : STD_LOGIC_VECTOR(31 DOWNTO 0);
    SIGNAL instr : STD_LOGIC_VECTOR(31 DOWNTO 0);
    SIGNAL readdata : STD_LOGIC_VECTOR(31 DOWNTO 0);
    
    -- Sinais do cache de instruções
    SIGNAL icache_stall : STD_LOGIC;
    SIGNAL imem_addr : STD_LOGIC_VECTOR(5 DOWNTO 0);
    SIGNAL imem_data : STD_LOGIC_VECTOR(31 DOWNTO 0);
    
    -- Sinais do cache de dados
    SIGNAL dcache_stall : STD_LOGIC;
    SIGNAL dmem_we : STD_LOGIC;
    SIGNAL dmem_addr_full : STD_LOGIC_VECTOR(31 DOWNTO 0);
    SIGNAL dmem_addr : STD_LOGIC_VECTOR(7 DOWNTO 0);
    SIGNAL dmem_din, dmem_dout : STD_LOGIC_VECTOR(31 DOWNTO 0);
    
    -- Clock modificado para incluir stalls
    SIGNAL mips_clk : STD_LOGIC;
    
BEGIN
    -- Clock do MIPS para quando há stall
    mips_clk <= clk AND NOT (icache_stall OR dcache_stall);
    
    -- Instancia o processador MIPS
    mips_inst: mips 
        PORT MAP (
            clk => mips_clk,
            reset => reset,
            pc => pc,
            instr => instr,
            memwrite => memwrite,
            aluout => dataadr,
            writedata => writedata,
            readdata => readdata
        );
    
    -- Instancia o cache de instruções
    icache: cache_instr
        GENERIC MAP (
            CACHE_LINES => 16,
            ADDR_WIDTH => 6
        )
        PORT MAP (
            clk => clk,
            reset => reset,
            addr => pc,
            instr_out => instr,
            stall => icache_stall,
            mem_addr => imem_addr,
            mem_data => imem_data,
            hit_count => icache_hits,
            miss_count => icache_misses
        );
    
    -- Instancia a memória de instruções
    imem_inst: imem
        PORT MAP (
            a => imem_addr,
            rd => imem_data
        );
    
    -- Instancia o cache de dados
    dcache: cache_data
        GENERIC MAP (
            CACHE_LINES => 16,
            ADDR_WIDTH => 8
        )
        PORT MAP (
            clk => clk,
            reset => reset,
            we => memwrite,
            addr => dataadr,
            data_in => writedata,
            data_out => readdata,
            stall => dcache_stall,
            mem_we => dmem_we,
            mem_addr => dmem_addr,
            mem_din => dmem_din,
            mem_dout => dmem_dout,
            hit_count => dcache_hits,
            miss_count => dcache_misses
        );
    
    -- Instancia a memória de dados
    dmem_addr_full <= (31 DOWNTO 8 => '0') & dmem_addr;
    dmem_inst: dmem
        PORT MAP (
            clk => clk,
            we => dmem_we,
            a => dmem_addr_full,
            wd => dmem_din,
            rd => dmem_dout
        );
    
END arch;

-- ============================================================================
-- DOCUMENTAÇÃO
-- ============================================================================
--
-- DIFERENÇAS EM RELAÇÃO AO TOP ORIGINAL (sem cache):
--
-- 1. CACHE DE INSTRUÇÕES:
--    - Intercepta acessos do PC à memória de instruções
--    - Em HIT: entrega instrução imediatamente
--    - Em MISS: busca da IMEM e atualiza cache (1 ciclo extra)
--
-- 2. CACHE DE DADOS:
--    - Intercepta leituras/escritas do processador à memória de dados
--    - Em HIT de leitura: retorna dado do cache
--    - Em MISS de leitura: busca da DMEM (1 ciclo extra)
--    - Em escrita: Write-Through (escreve cache + memória)
--
-- 3. MECANISMO DE STALL:
--    - Quando há miss, o sinal 'stall' é ativado
--    - O clock do MIPS é pausado: mips_clk = clk AND NOT stall
--    - Processador fica congelado até o cache resolver o miss
--
-- 4. ESTATÍSTICAS:
--    - icache_hits/misses: Performance do cache de instruções
--    - dcache_hits/misses: Performance do cache de dados
--    - Hit Rate = hits / (hits + misses)
--
-- ANÁLISE DE DESEMPENHO:
-- Compare este design com o 'top.vhd' original (sem cache):
-- - Conte ciclos totais de execução
-- - Calcule speedup = ciclos_sem_cache / ciclos_com_cache
-- - Analise hit rates para diferentes tamanhos de cache
--
-- ============================================================================