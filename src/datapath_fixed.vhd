LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.NUMERIC_STD.ALL;

ENTITY datapath IS -- MIPS datapath
    PORT (
        clk, reset : IN STD_LOGIC;
        memtoreg, pcsrc : IN STD_LOGIC;
        alusrc, regdst : IN STD_LOGIC;
        regwrite, jump : IN STD_LOGIC;
        alucontrol : IN STD_LOGIC_VECTOR(3 DOWNTO 0); -- EXPANDIDO de 2 para 4 bits
        zero : OUT STD_LOGIC;
        pc : BUFFER STD_LOGIC_VECTOR(31 DOWNTO 0);
        instr : IN STD_LOGIC_VECTOR(31 DOWNTO 0);
        aluout, writedata : BUFFER STD_LOGIC_VECTOR(31 DOWNTO 0);
        readdata : IN STD_LOGIC_VECTOR(31 DOWNTO 0)
    );
END;

ARCHITECTURE struct OF datapath IS
    -- Componente ALU unificada (inteiro + FP)
    COMPONENT alu_unified PORT (
        clk : IN STD_LOGIC;
        a, b : IN STD_LOGIC_VECTOR(31 DOWNTO 0);
        alucontrol : IN STD_LOGIC_VECTOR(3 DOWNTO 0); -- 4 bits
        result : OUT STD_LOGIC_VECTOR(31 DOWNTO 0);
        zero : OUT STD_LOGIC;
        fp_flags : OUT STD_LOGIC_VECTOR(5 DOWNTO 0)
    );
    END COMPONENT;
    
    COMPONENT regfile PORT (
        clk : IN STD_LOGIC;
        we3 : IN STD_LOGIC;
        ra1, ra2, wa3 : IN STD_LOGIC_VECTOR(4 DOWNTO 0);
        wd3 : IN STD_LOGIC_VECTOR(31 DOWNTO 0);
        rd1, rd2 : OUT STD_LOGIC_VECTOR(31 DOWNTO 0)
    );
    END COMPONENT;
    
    COMPONENT adder PORT (
        a, b : IN STD_LOGIC_VECTOR(31 DOWNTO 0);
        y : OUT STD_LOGIC_VECTOR(31 DOWNTO 0)
    );
    END COMPONENT;
    
    COMPONENT sl2 PORT (
        a : IN STD_LOGIC_VECTOR(31 DOWNTO 0);
        y : OUT STD_LOGIC_VECTOR(31 DOWNTO 0)
    );
    END COMPONENT;
    
    COMPONENT signext PORT (
        a : IN STD_LOGIC_VECTOR(15 DOWNTO 0);
        y : OUT STD_LOGIC_VECTOR(31 DOWNTO 0)
    );
    END COMPONENT;
    
    COMPONENT flopr GENERIC (width : INTEGER);
        PORT (
            clk, reset : IN STD_LOGIC;
            d : IN STD_LOGIC_VECTOR(width - 1 DOWNTO 0);
            q : OUT STD_LOGIC_VECTOR(width - 1 DOWNTO 0)
        );
    END COMPONENT;
    
    COMPONENT mux2 GENERIC (width : INTEGER);
        PORT (
            d0, d1 : IN STD_LOGIC_VECTOR(width - 1 DOWNTO 0);
            s : IN STD_LOGIC;
            y : OUT STD_LOGIC_VECTOR(width - 1 DOWNTO 0)
        );
    END COMPONENT;

    SIGNAL writereg : STD_LOGIC_VECTOR(4 DOWNTO 0);
    SIGNAL pcjump, pcnext, pcnextbr, pcplus4, pcbranch : STD_LOGIC_VECTOR(31 DOWNTO 0);
    SIGNAL signimm, signimmsh : STD_LOGIC_VECTOR(31 DOWNTO 0);
    SIGNAL srca, srcb, result : STD_LOGIC_VECTOR(31 DOWNTO 0);
    SIGNAL fp_flags_unused : STD_LOGIC_VECTOR(5 DOWNTO 0); -- Flags FP não usadas por enquanto
    
BEGIN
    -- next PC logic
    pcjump <= pcplus4(31 DOWNTO 28) & instr(25 DOWNTO 0) & "00";
    pcreg : flopr GENERIC MAP(32) PORT MAP(clk, reset, pcnext, pc);
    pcadd1 : adder PORT MAP(pc, X"00000004", pcplus4);
    immsh : sl2 PORT MAP(signimm, signimmsh);
    pcadd2 : adder PORT MAP(pcplus4, signimmsh, pcbranch);
    pcbrmux : mux2 GENERIC MAP(32) PORT MAP(pcplus4, pcbranch, pcsrc, pcnextbr);
    pcmux : mux2 GENERIC MAP(32) PORT MAP(pcnextbr, pcjump, jump, pcnext);

    -- register file logic
    rf : regfile PORT MAP(clk, regwrite, instr(25 DOWNTO 21), instr(20 DOWNTO 16), writereg, result, srca, writedata);
    wrmux : mux2 GENERIC MAP(5) PORT MAP(instr(20 DOWNTO 16), instr(15 DOWNTO 11), regdst, writereg);
    resmux : mux2 GENERIC MAP(32) PORT MAP(aluout, readdata, memtoreg, result);
    se : signext PORT MAP(instr(15 DOWNTO 0), signimm);

    -- ALU logic (agora com suporte a FP)
    srcbmux : mux2 GENERIC MAP(32) PORT MAP(writedata, signimm, alusrc, srcb);
    mainalu : alu_unified PORT MAP(
        clk => clk,                -- Clock adicionado para ALU FP
        a => srca, 
        b => srcb, 
        alucontrol => alucontrol,  -- Agora 4 bits
        result => aluout, 
        zero => zero,
        fp_flags => fp_flags_unused -- Não usado no processador básico
    );
END;