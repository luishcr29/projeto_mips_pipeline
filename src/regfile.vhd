LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.NUMERIC_STD.ALL;

ENTITY regfile IS -- three-port register file
    PORT (
        clk : IN STD_LOGIC;
        we3 : IN STD_LOGIC;
        ra1, ra2, wa3 : IN STD_LOGIC_VECTOR(4 DOWNTO 0);
        wd3 : IN STD_LOGIC_VECTOR(31 DOWNTO 0);
        rd1, rd2 : OUT STD_LOGIC_VECTOR(31 DOWNTO 0)
    );
END;

ARCHITECTURE behave OF regfile IS
    TYPE ramtype IS ARRAY (31 DOWNTO 0) OF STD_LOGIC_VECTOR(31 DOWNTO 0);
    SIGNAL mem : ramtype := (OTHERS => (OTHERS => '0'));

    -- CHG: função auxiliar para detectar se um vetor contém 'U', 'X', 'Z'
    FUNCTION is_defined(v : STD_LOGIC_VECTOR) RETURN BOOLEAN IS
    BEGIN
        FOR i IN v'RANGE LOOP
            IF v(i) /= '0' AND v(i) /= '1' THEN
                RETURN false;
            END IF;
        END LOOP;
        RETURN true;
    END FUNCTION;

BEGIN

    -- CHG: escrita na borda de subida
    PROCESS (clk)
    BEGIN
        IF rising_edge(clk) THEN
            IF we3 = '1' AND is_defined(wa3) THEN -- protege conversão
                IF to_integer(unsigned(wa3)) /= 0 THEN
                    mem(to_integer(unsigned(wa3))) <= wd3;
                END IF;
            END IF;
        END IF;
    END PROCESS;

    -- CHG: leitura combinacional com checagem de validade
    PROCESS (ALL)
    BEGIN
        IF is_defined(ra1) THEN
            IF to_integer(unsigned(ra1)) = 0 THEN
                rd1 <= (OTHERS => '0');
            ELSE
                rd1 <= mem(to_integer(unsigned(ra1)));
            END IF;
        ELSE
            rd1 <= (OTHERS => '0');
        END IF;

        IF is_defined(ra2) THEN
            IF to_integer(unsigned(ra2)) = 0 THEN
                rd2 <= (OTHERS => '0');
            ELSE
                rd2 <= mem(to_integer(unsigned(ra2)));
            END IF;
        ELSE
            rd2 <= (OTHERS => '0');
        END IF;
    END PROCESS;

END;