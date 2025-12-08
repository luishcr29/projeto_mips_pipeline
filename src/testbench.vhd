LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.NUMERIC_STD.ALL;

ENTITY testbench IS
END;

ARCHITECTURE test OF testbench IS
    -- Componente 'top' (processador MIPS)
    COMPONENT top PORT (
        clk, reset : IN STD_LOGIC;
        writedata, dataadr : OUT STD_LOGIC_VECTOR(31 DOWNTO 0);
        memwrite : OUT STD_LOGIC
    );
    END COMPONENT;
    
    -- Sinais para conectar ao 'top'
    SIGNAL writedata, dataadr : STD_LOGIC_VECTOR(31 DOWNTO 0);
    SIGNAL clk, reset, memwrite : STD_LOGIC;
    
BEGIN
    -- Instancia o dispositivo a ser testado (dut)
    dut : top PORT MAP(clk, reset, writedata, dataadr, memwrite);
    
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
    
    -- =================================================================
    --  PROCESSO DE TIMEOUT
    -- =================================================================
    timeout_process : PROCESS
    BEGIN
        WAIT FOR 1000 ns;  -- ← VOCÊ PODE AJUSTAR ESTE VALOR
        REPORT "TIMEOUT: Simulacao encerrada apos 1000 ns." SEVERITY failure;
        WAIT;
    END PROCESS;
    
    -- =================================================================
    --  PROCESSO MONITOR (MODIFICADO - NÃO PARA A SIMULAÇÃO)
    -- =================================================================
    monitor : PROCESS (clk)
    BEGIN
        IF (clk'event AND clk = '0') THEN
            IF (memwrite = '1') THEN
                IF (to_integer(unsigned(dataadr)) = 84) THEN
                    IF (to_integer(unsigned(writedata)) = 7) THEN
                        -- ★ MUDADO DE 'failure' PARA 'note' ★
                        REPORT "NO ERRORS: O valor 7 foi escrito no endereco 84. Simulacao SUCESSO." 
                            SEVERITY note;
                    ELSE
                        -- ★ MUDADO DE 'failure' PARA 'warning' ★
                        REPORT "FALHA: Escrita no endereco 84 com valor incorreto: " &
                            INTEGER'image(to_integer(unsigned(writedata))) &
                            " (Esperava 7)." SEVERITY warning;
                    END IF;
                ELSIF (to_integer(unsigned(dataadr)) = 80) THEN
                    REPORT "NOTA: Detectada escrita no endereco 80 (sw $7, 68($3))." SEVERITY note;
                END IF;
            END IF;
        END IF;
    END PROCESS;
END;