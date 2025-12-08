LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
ENTITY flopr IS
    GENERIC (width : INTEGER);
    PORT (
        clk, reset : IN STD_LOGIC;
        d : IN STD_LOGIC_VECTOR(width - 1 DOWNTO 0);
        q : OUT STD_LOGIC_VECTOR(width - 1 DOWNTO 0));
END;
ARCHITECTURE asynchronous OF flopr IS
BEGIN
    PROCESS (clk, reset)
    BEGIN
        IF reset = '1' THEN
            q <= (OTHERS => '0');
        ELSIF rising_edge(clk) THEN
            q <= d;
        END IF;
    END PROCESS;
END;