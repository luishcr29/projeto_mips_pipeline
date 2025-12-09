LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.NUMERIC_STD.ALL;
USE STD.TEXTIO.ALL;
ENTITY dmem IS -- data memory
    PORT (
        clk, we : IN STD_LOGIC;
        a, wd : IN STD_LOGIC_VECTOR (31 DOWNTO 0);
        rd : OUT STD_LOGIC_VECTOR (31 DOWNTO 0));
END;

ARCHITECTURE behave OF dmem IS
    -- Array de 64 posições de 32 bits
    TYPE ramtype IS ARRAY (63 DOWNTO 0) OF STD_LOGIC_VECTOR(31 DOWNTO 0);
    -- Inicializa toda a memória com 0
    SIGNAL mem : ramtype := (OTHERS => (OTHERS => '0'));

BEGIN

    -- CORREÇÃO 1: A ESCRITA (sw) deve ser SÍNCRONA.
    -- Ela só acontece na borda de subida do clock E se we = '1'.
    -- Isso está em seu próprio processo.
    write_process : PROCESS (clk)
    BEGIN
        IF rising_edge(clk) THEN
            IF we = '1' THEN
                -- Usa os bits [7:2] do endereço para indexar a memória de 64 palavras
                mem(to_integer(unsigned(a(7 DOWNTO 2)))) <= wd;
            END IF;
        END IF;
    END PROCESS;
    -- CORREÇÃO 2: A LEITURA (lw) deve ser COMBINACIONAL (ASSÍNCRONA).
    -- O processador single-cycle precisa ler o dado IMEDIATAMENTE.
    -- Esta linha NÃO está dentro de um processo de clock.
    -- Assim que 'a' muda, 'rd' é atualizado.
    rd <= mem(to_integer(unsigned(a(7 DOWNTO 2))));

END;