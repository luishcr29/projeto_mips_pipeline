LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;

ENTITY mips IS -- single cycle MIPS processor
    PORT (
        clk, reset : IN STD_LOGIC;
        pc : OUT STD_LOGIC_VECTOR(31 DOWNTO 0);
        instr : IN STD_LOGIC_VECTOR(31 DOWNTO 0);
        memwrite : OUT STD_LOGIC;
        aluout, writedata : OUT STD_LOGIC_VECTOR(31 DOWNTO 0);
        readdata : IN STD_LOGIC_VECTOR(31 DOWNTO 0)
    );
END;

ARCHITECTURE struct OF mips IS
    COMPONENT controller PORT (
        op, funct : IN STD_LOGIC_VECTOR(5 DOWNTO 0);
        zero : IN STD_LOGIC;
        memtoreg, memwrite : OUT STD_LOGIC;
        pcsrc, alusrc : OUT STD_LOGIC;
        regdst, regwrite : OUT STD_LOGIC;
        jump : OUT STD_LOGIC;
        alucontrol : OUT STD_LOGIC_VECTOR(3 DOWNTO 0) -- CORRIGIDO: 4 bits
    );
    END COMPONENT;
    
    COMPONENT datapath PORT (
        clk, reset : IN STD_LOGIC;
        memtoreg, pcsrc : IN STD_LOGIC;
        alusrc, regdst : IN STD_LOGIC;
        regwrite, jump : IN STD_LOGIC;
        alucontrol : IN STD_LOGIC_VECTOR(3 DOWNTO 0); -- CORRIGIDO: 4 bits
        zero : OUT STD_LOGIC;
        pc : BUFFER STD_LOGIC_VECTOR(31 DOWNTO 0);
        instr : IN STD_LOGIC_VECTOR(31 DOWNTO 0);
        aluout, writedata : BUFFER STD_LOGIC_VECTOR(31 DOWNTO 0);
        readdata : IN STD_LOGIC_VECTOR(31 DOWNTO 0)
    );
    END COMPONENT;

    SIGNAL memtoreg, alusrc, regdst, regwrite, jump, pcsrc : STD_LOGIC;
    SIGNAL zero : STD_LOGIC;
    SIGNAL alucontrol : STD_LOGIC_VECTOR(3 DOWNTO 0); -- CORRIGIDO: 4 bits
    
BEGIN
    cont : controller PORT MAP(
        op => instr(31 DOWNTO 26), 
        funct => instr(5 DOWNTO 0), 
        zero => zero, 
        memtoreg => memtoreg, 
        memwrite => memwrite, 
        pcsrc => pcsrc, 
        alusrc => alusrc, 
        regdst => regdst, 
        regwrite => regwrite, 
        jump => jump, 
        alucontrol => alucontrol
    );
    
    dp : datapath PORT MAP(
        clk => clk, 
        reset => reset, 
        memtoreg => memtoreg, 
        pcsrc => pcsrc, 
        alusrc => alusrc, 
        regdst => regdst, 
        regwrite => regwrite, 
        jump => jump, 
        alucontrol => alucontrol, 
        zero => zero, 
        pc => pc, 
        instr => instr, 
        aluout => aluout, 
        writedata => writedata, 
        readdata => readdata
    );
END;