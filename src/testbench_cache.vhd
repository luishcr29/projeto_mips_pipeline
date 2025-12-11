LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.NUMERIC_STD.ALL;

ENTITY testbench_cache IS
END testbench_cache;

ARCHITECTURE test OF testbench_cache IS
    -- Componente 'top_with_cache' (processador MIPS com cache)
    COMPONENT top_with_cache 
        PORT (
            clk, reset : IN STD_LOGIC;
            writedata, dataadr : OUT STD_LOGIC_VECTOR(31 DOWNTO 0);
            memwrite : OUT STD_LOGIC;
            icache_hits, icache_misses : OUT INTEGER;
            dcache_hits, dcache_misses : OUT INTEGER
        );
    END COMPONENT;
    
    -- Sinais para conectar ao 'top_with_cache'
    SIGNAL writedata, dataadr : STD_LOGIC_VECTOR(31 DOWNTO 0);
    SIGNAL clk, reset, memwrite : STD_LOGIC;
    SIGNAL icache_hits, icache_misses : INTEGER;
    SIGNAL dcache_hits, dcache_misses : INTEGER;
    
    -- Contador de ciclos
    SIGNAL cycle_count : INTEGER := 0;
    
BEGIN
    -- Instancia o dispositivo a ser testado (dut)
    dut : top_with_cache 
        PORT MAP(
            clk => clk, 
            reset => reset, 
            writedata => writedata, 
            dataadr => dataadr, 
            memwrite => memwrite,
            icache_hits => icache_hits,
            icache_misses => icache_misses,
            dcache_hits => dcache_hits,
            dcache_misses => dcache_misses
        );
    
    -- Gera clock com período de 10 ns
    clk_process : PROCESS
    BEGIN
        clk <= '1';
        WAIT FOR 5 ns;
        clk <= '0';
        WAIT FOR 5 ns;
    END PROCESS;
    
    -- Gera reset para os primeiros ~2 ciclos de clock
    reset_process : PROCESS
    BEGIN
        reset <= '1';
        WAIT FOR 22 ns;
        reset <= '0';
        WAIT;
    END PROCESS;
    
    -- Contador de ciclos
    cycle_counter : PROCESS(clk)
    BEGIN
        IF rising_edge(clk) THEN
            IF reset = '0' THEN
                cycle_count <= cycle_count + 1;
            END IF;
        END IF;
    END PROCESS;
    
    -- =================================================================
    --  PROCESSO DE TIMEOUT
    -- =================================================================
    timeout_process : PROCESS
    BEGIN
        WAIT FOR 2000 ns;  -- Timeout aumentado por causa do cache
        
        -- Relatório final de estatísticas
        REPORT "=================================================";
        REPORT "SIMULACAO ENCERRADA - RELATORIO FINAL";
        REPORT "=================================================";
        REPORT "Total de ciclos executados: " & INTEGER'image(cycle_count);
        REPORT "";
        REPORT "CACHE DE INSTRUCOES:";
        REPORT "  Hits:  " & INTEGER'image(icache_hits);
        REPORT "  Misses: " & INTEGER'image(icache_misses);
        IF (icache_hits + icache_misses) > 0 THEN
            REPORT "  Hit Rate: " & 
                INTEGER'image((icache_hits * 100) / (icache_hits + icache_misses)) & "%";
        END IF;
        REPORT "";
        REPORT "CACHE DE DADOS:";
        REPORT "  Hits:  " & INTEGER'image(dcache_hits);
        REPORT "  Misses: " & INTEGER'image(dcache_misses);
        IF (dcache_hits + dcache_misses) > 0 THEN
            REPORT "  Hit Rate: " & 
                INTEGER'image((dcache_hits * 100) / (dcache_hits + dcache_misses)) & "%";
        END IF;
        REPORT "=================================================";
        
        REPORT "TIMEOUT: Simulacao encerrada apos 2000 ns." SEVERITY failure;
        WAIT;
    END PROCESS;
    
    -- =================================================================
    --  PROCESSO MONITOR (MODIFICADO)
    -- =================================================================
    monitor : PROCESS (clk)
    BEGIN
        IF (clk'event AND clk = '0') THEN
            IF (memwrite = '1') THEN
                REPORT "Ciclo " & INTEGER'image(cycle_count) & 
                       ": Escrita em addr=" & INTEGER'image(to_integer(unsigned(dataadr))) &
                       ", data=" & INTEGER'image(to_integer(unsigned(writedata)))
                    SEVERITY note;
                
                IF (to_integer(unsigned(dataadr)) = 84) THEN
                    IF (to_integer(unsigned(writedata)) = 7) THEN
                        REPORT "===============================================" SEVERITY note;
                        REPORT "[SUCESSO] Valor 7 escrito no endereco 84." SEVERITY note;
                        REPORT "===============================================" SEVERITY note;
                        REPORT "" SEVERITY note;
                        REPORT "ESTATISTICAS DO CACHE:" SEVERITY note;
                        REPORT "  ICache - Hits: " & INTEGER'image(icache_hits) & 
                               ", Misses: " & INTEGER'image(icache_misses) SEVERITY note;
                        REPORT "  DCache - Hits: " & INTEGER'image(dcache_hits) & 
                               ", Misses: " & INTEGER'image(dcache_misses) SEVERITY note;
                        REPORT "===============================================" SEVERITY note;
                    ELSE
                        REPORT "[FALHA] Valor incorreto no endereco 84: " &
                            INTEGER'image(to_integer(unsigned(writedata))) &
                            " (Esperava 7)." SEVERITY warning;
                    END IF;
                END IF;
            END IF;
        END IF;
    END PROCESS;
    
    -- =================================================================
    --  MONITOR DE CACHE (Opcional - para debug)
    -- =================================================================
    cache_monitor : PROCESS(clk)
    BEGIN
        IF rising_edge(clk) THEN
            IF reset = '0' AND cycle_count MOD 10 = 0 THEN
                REPORT "Ciclo " & INTEGER'image(cycle_count) & 
                       " | ICache: " & INTEGER'image(icache_hits) & "/" & 
                       INTEGER'image(icache_hits + icache_misses) &
                       " | DCache: " & INTEGER'image(dcache_hits) & "/" & 
                       INTEGER'image(dcache_hits + dcache_misses)
                    SEVERITY note;
            END IF;
        END IF;
    END PROCESS;
    
END test;