drop database if exists toomate;
create database if not exists toomate;
USE toomate;

drop user if exists 'toomate_user'@'%';
create user 'toomate_user'@'%' identified by 'toomate_password';
grant all on toomate.* to 'toomate_user'@'%';

flush privileges;

/*
*/
CREATE TABLE Usuario (
    idUsuario INT PRIMARY KEY AUTO_INCREMENT,
    nome VARCHAR(45),
    apelido VARCHAR(45),
    senha CHAR(64),
    administrador TINYINT
);

CREATE TABLE categoria (
    idCategoria INT PRIMARY KEY AUTO_INCREMENT,
    nome VARCHAR(45)
);

CREATE TABLE insumo (
    idInsumo INT PRIMARY KEY AUTO_INCREMENT,
    fkCategoria INT,
    nome VARCHAR(45),
    qtdMinima INT,
    rotatividade TINYINT,
    CONSTRAINT fk_insumo_categoria FOREIGN KEY (fkCategoria) REFERENCES categoria(idCategoria)
);

CREATE TABLE rotina (
    idRotina INT PRIMARY KEY AUTO_INCREMENT,
    titulo VARCHAR(45)
);

CREATE TABLE rotinaInsumo (
    id INT PRIMARY KEY AUTO_INCREMENT,
    idRotina INT,
    idInsumo INT,
    quantidadeInsumo INT,
    CONSTRAINT fk_rotinaInsumo_rotina FOREIGN KEY (idRotina) REFERENCES rotina(idRotina),
    CONSTRAINT fk_rotinaInsumo_insumo FOREIGN KEY (idInsumo) REFERENCES insumo(idInsumo)
);

CREATE TABLE fornecedor (
    idFornecedor INT PRIMARY KEY AUTO_INCREMENT,
    linkWhatsapp VARCHAR(100),
    razaoSocial VARCHAR(45),
    telefone VARCHAR(45)
);

CREATE TABLE marca (
    idMarca INT PRIMARY KEY AUTO_INCREMENT,
    fkInsumo INT,
    fkFornecedor INT,
    nomeMarca VARCHAR(45),
    CONSTRAINT fk_marca_insumo FOREIGN KEY (fkInsumo) REFERENCES insumo(idInsumo),
    CONSTRAINT fk_marca_fornecedor FOREIGN KEY (fkFornecedor) REFERENCES fornecedor(idFornecedor)
);

CREATE TABLE lote (
    idLote INT PRIMARY KEY AUTO_INCREMENT,
    dataValidade DATE,
    precoUnit DECIMAL(5,2),
    unidadeMedida VARCHAR(20),
    quantidadeMedida DOUBLE,
    quantidadeTotal INT,
    dataEntrada DATE,
    fkMarca INT,
    fkUsuario INT,
    CONSTRAINT fk_lote_marca FOREIGN KEY (fkMarca) REFERENCES marca(idMarca),
    CONSTRAINT fk_lote_usuario FOREIGN KEY (fkUsuario) REFERENCES Usuario(idUsuario)
);

CREATE TABLE arquivo (
    idArquivo INT PRIMARY KEY AUTO_INCREMENT,
    nomeOriginal VARCHAR(45),
    chave VARCHAR(45),
    nomeBucket VARCHAR(45),
    dtCriacao DATETIME,
    dtAlteracao DATETIME
);

CREATE TABLE arquivoRelacionamento (
    id INT PRIMARY KEY AUTO_INCREMENT,
    fkArquivo INT,
    tipoEntidade VARCHAR(45),
    idEntidade INT,
	CONSTRAINT fk_arq_rel_arquivo FOREIGN KEY (fkArquivo) REFERENCES arquivo(idArquivo)
);

CREATE TABLE cliente (
    idCliente INT PRIMARY KEY AUTO_INCREMENT,
    nome VARCHAR(45),
    telefone VARCHAR(45),
    cep VARCHAR(45),
    logradouro VARCHAR(45),
    bairro VARCHAR(45)
);

CREATE TABLE divida (
    idDivida INT PRIMARY KEY AUTO_INCREMENT,
    valor DECIMAL(6,2),
    dataCompra DATETIME,
    dataPagamento DATETIME,
    pedido VARCHAR(200),
    pago TINYINT,
    fkCliente INT,
    CONSTRAINT fk_divida_cliente FOREIGN KEY (fkCliente) REFERENCES cliente(idCliente)
);

CREATE TABLE boleto (
    idBoleto INT PRIMARY KEY AUTO_INCREMENT,
    descricao VARCHAR(45),
    categoria VARCHAR(20),
    pago TINYINT,
    dataVencimento DATETIME,
    dataPagamento DATETIME,
    valor DECIMAL(6,2),
    fkFornecedor INT,
    CONSTRAINT fk_boleto_fornecedor FOREIGN KEY (fkFornecedor) REFERENCES fornecedor(idFornecedor)
);


-- VIEWS
-- 1. KPI: Itens vencendo em 7 dias ou menos (incluindo vencidos)
CREATE VIEW vw_kpi_validade_proxima AS
SELECT 
    i.nome AS Insumo, 
    l.dataValidade, 
    l.quantidadeTotal AS QtdAtual,
    DATEDIFF(l.dataValidade, CURDATE()) AS DiasParaVencer
FROM lote l
JOIN marca m ON l.fkMarca = m.idMarca
JOIN insumo i ON m.fkInsumo = i.idInsumo
WHERE l.dataValidade <= DATE_ADD(CURDATE(), INTERVAL 7 DAY);


-- 2. KPI: Itens com estoque abaixo ou igual ao mínimo
CREATE VIEW vw_kpi_estoque_baixo AS
SELECT 
    i.nome AS Insumo,
    SUM(l.quantidadeTotal) AS EstoqueTotal,
    i.qtdMinima
FROM insumo i
LEFT JOIN marca m ON i.idInsumo = m.fkInsumo
LEFT JOIN lote l ON m.idMarca = l.fkMarca
GROUP BY i.idInsumo, i.nome, i.qtdMinima
HAVING EstoqueTotal <= i.qtdMinima OR EstoqueTotal IS NULL;


-- 3. KPI: Contas (Boletos) já vencidas
CREATE VIEW vw_kpi_contas_atrasadas AS
SELECT count(*) as QtdAtrasadas
FROM boleto
WHERE pago = 0 AND dataVencimento < CURDATE();


-- 4. Gráfico: Estoque Atual vs Mínimo (Para visualização)
CREATE VIEW vw_grafico_estoque_vs_minimo AS
SELECT 
    i.nome AS Insumo,
    COALESCE(SUM(l.quantidadeTotal), 0) AS EstoqueAtual,
    i.qtdMinima AS EstoqueMinimo,
    CASE 
        WHEN COALESCE(SUM(l.quantidadeTotal), 0) < i.qtdMinima THEN 'Repor Urgente'
        ELSE 'OK' 
    END AS Status
FROM insumo i
LEFT JOIN marca m ON i.idInsumo = m.fkInsumo
LEFT JOIN lote l ON m.idMarca = l.fkMarca
GROUP BY i.idInsumo, i.nome, i.qtdMinima;


-- 5. KPI: Boletos vencendo nos próximos 7 dias
CREATE VIEW vw_kpi_boletos_vencimento_proximo AS
SELECT * FROM boleto
WHERE pago = 0 
  AND dataVencimento BETWEEN CURDATE() AND DATE_ADD(CURDATE(), INTERVAL 7 DAY);


-- 6. Soma: Valor total de contas que vencem nesta semana
CREATE VIEW vw_total_contas_semana AS
SELECT COALESCE(SUM(valor), 0) AS ValorTotalSemana
FROM boleto
WHERE YEARWEEK(dataVencimento, 1) = YEARWEEK(CURDATE(), 1);


-- 7. Análise: Boleto "Em aberto" de maior valor
CREATE VIEW vw_boleto_maior_valor_aberto AS
SELECT * FROM boleto
WHERE pago = 0
ORDER BY valor DESC
LIMIT 1;


-- 8. KPI: Boletos que vencem no mês atual (Independente de pago ou não)
CREATE VIEW vw_kpi_boletos_mes_atual AS
SELECT count(*) AS QtdBoletosMes
FROM boleto
WHERE MONTH(dataVencimento) = MONTH(CURDATE()) 
  AND YEAR(dataVencimento) = YEAR(CURDATE());


-- 9. Soma: Valor total de contas "Em atraso"
CREATE VIEW vw_total_valor_atrasado AS
SELECT COALESCE(SUM(valor), 0) AS TotalDividaFornecedor
FROM boleto
WHERE pago = 0 AND dataVencimento < CURDATE();


-- 10. Soma: Valor total que clientes devem ao estabelecimento
CREATE VIEW vw_total_divida_clientes AS
SELECT COALESCE(SUM(valor), 0) AS TotalReceber
FROM divida
WHERE pago = 0;


-- 11. Análise: Cliente com a maior dívida acumulada
CREATE VIEW vw_cliente_maior_devedor AS
SELECT 
    c.nome, 
    c.telefone, 
    SUM(d.valor) AS TotalDevido
FROM cliente c
JOIN divida d ON c.idCliente = d.fkCliente
WHERE d.pago = 0
GROUP BY c.idCliente, c.nome, c.telefone
ORDER BY TotalDevido DESC
LIMIT 1;


-- 12. Análise: Pedido em aberto mais antigo
CREATE VIEW vw_pedido_aberto_mais_antigo AS
SELECT 
    c.nome AS Cliente,
    d.dataCompra,
    d.valor,
    d.pedido,
    DATEDIFF(CURDATE(), d.dataCompra) AS DiasEmAberto
FROM divida d
JOIN cliente c ON d.fkCliente = c.idCliente
WHERE d.pago = 0
ORDER BY d.dataCompra ASC
LIMIT 1;


-- 13. Predição: Item que provavelmente faltará (Estoque < 10% acima do mínimo)
-- Lógica: Ordena pelos itens que estão mais próximos da margem de segurança
CREATE VIEW vw_predicao_falta_estoque AS
SELECT 
    i.nome AS Insumo,
    SUM(l.quantidadeTotal) AS EstoqueAtual,
    i.qtdMinima,
    (SUM(l.quantidadeTotal) - i.qtdMinima) AS MargemSeguranca
FROM insumo i
JOIN marca m ON i.idInsumo = m.fkInsumo
JOIN lote l ON m.idMarca = l.fkMarca
GROUP BY i.idInsumo, i.nome, i.qtdMinima
HAVING EstoqueAtual > 0 
ORDER BY MargemSeguranca ASC
LIMIT 1;

-- 14. Predição: Item que provavelmente vencerá antes de ser usado
-- Lógica: Itens com muita quantidade em estoque mas validade muito curta (ex: vence em 3 dias)
CREATE VIEW vw_predicao_perda_validade AS
SELECT 
    i.nome AS Insumo,
    l.quantidadeTotal AS QtdNoLote,
    l.dataValidade,
    DATEDIFF(l.dataValidade, CURDATE()) AS DiasRestantes
FROM lote l
JOIN marca m ON l.fkMarca = m.idMarca
JOIN insumo i ON m.fkInsumo = i.idInsumo
WHERE l.dataValidade > CURDATE() -- Ainda não venceu
  AND DATEDIFF(l.dataValidade, CURDATE()) <= 5 -- Vence em 5 dias ou menos
ORDER BY l.quantidadeTotal DESC -- Prioriza os que tem maior quantidade em risco
LIMIT 1;


-- 15. Financeiro Estoque: Valor total de itens cadastrados na semana atual
CREATE VIEW vw_total_entrada_estoque_semana AS
SELECT 
    COALESCE(SUM(l.precoUnit * l.quantidadeTotal), 0) AS ValorTotalEntradas
FROM lote l
WHERE YEARWEEK(l.dataEntrada, 1) = YEARWEEK(CURDATE(), 1);


-- 16. Perda: Valor total de itens perdidos (Vencidos e ainda em estoque)
CREATE VIEW vw_total_perda_validade AS
SELECT 
    COALESCE(SUM(l.precoUnit * l.quantidadeTotal), 0) AS ValorTotalPerda
FROM lote l
WHERE l.dataValidade < CURDATE();

use toomate;

SET FOREIGN_KEY_CHECKS = 0;
TRUNCATE TABLE arquivoRelacionamento;
TRUNCATE TABLE arquivo;
TRUNCATE TABLE rotinaInsumo;
TRUNCATE TABLE rotina;
TRUNCATE TABLE lote;
TRUNCATE TABLE marca;
TRUNCATE TABLE divida;
TRUNCATE TABLE cliente;
TRUNCATE TABLE boleto;
TRUNCATE TABLE insumo;
TRUNCATE TABLE fornecedor;
TRUNCATE TABLE categoria;
TRUNCATE TABLE Usuario;
SET FOREIGN_KEY_CHECKS = 1;

INSERT INTO Usuario (nome, apelido, senha, administrador) VALUES
    ('Carlos Eduardo Silva',  'carlos',  'senha123', 1),
    ('Ana Paula Souza',       'ana',     'senha123', 0),
    ('Roberto Mendes',        'roberto', 'senha123', 0);

INSERT INTO categoria (nome) VALUES
    ('Proteínas'),               -- ID 1
    ('Pescados'),                -- ID 2
    ('Hortifruti'),              -- ID 3
    ('Laticínios'),              -- ID 4
    ('Frios e Embutidos'),       -- ID 5
    ('Grãos e Secos'),           -- ID 6
    ('Temperos e Condimentos'),  -- ID 7
    ('Óleos e Gorduras'),        -- ID 8
    ('Bebidas');                 -- ID 9

INSERT INTO fornecedor (razaoSocial, telefone, linkWhatsapp) VALUES
    ('Laticínios do Vale Ltda',         '(11) 5897-2493', 'https://wa.me/551158972493'),
    ('Frigorífico Central S.A.',        '(11) 5897-2493', 'https://wa.me/551158972493'),
    ('Distribuidora Grãos Brasil Ltda', '(11) 5897-2493', 'https://wa.me/551158972493'),
    ('Temperos & Cia Ltda',             '(11) 5897-2493', 'https://wa.me/551158972493'),
    ('Distribuidora de Bebidas S.A.',   '(11) 5897-2493', 'https://wa.me/551158972493');

INSERT INTO insumo (fkCategoria, nome, qtdMinima, rotatividade) VALUES
    (4, 'Leite Integral',      10, 1), -- ID 1
    (4, 'Queijo Mussarela',    5,  1), -- ID 2
    (1, 'Frango Inteiro',      8,  1), -- ID 3
    (1, 'Carne Bovina Moída',  10, 1), -- ID 4
    (6, 'Arroz Branco',        20, 0), -- ID 5
    (6, 'Feijão Carioca',      15, 0), -- ID 6
    (7, 'Sal Refinado',        5,  0), -- ID 7
    (8, 'Óleo de Soja',        6,  0), -- ID 8
    (9, 'Refrigerante 2L',     24, 0), -- ID 9
    (9, 'Água Mineral 500ml',  50, 0), -- ID 10
    (4, 'Creme de Leite',      8,  1), -- ID 11
    (4, 'Manteiga',            6,  1), -- ID 12
    (4, 'Requeijao Cremoso',   5,  1), -- ID 13
    (4, 'Leite Condensado',    10, 1), -- ID 14
    (4, 'Queijo Prato',        7,  1), -- ID 15
    (1, 'Peito de Frango',     9,  1), -- ID 16
    (1, 'Coxa e Sobrecoxa',    9,  1), -- ID 17
    (1, 'Carne Suina',         8,  1), -- ID 18
    (5, 'Linguica Toscana',    7,  1), -- ID 19
    (5, 'Bacon',               6,  1), -- ID 20
    (2, 'File de Tilapia',     6,  1), -- ID 21
    (6, 'Acucar Refinado',     18, 0), -- ID 22
    (6, 'Farinha de Trigo',    16, 0), -- ID 23
    (6, 'Macarrao Espaguete',  20, 0), -- ID 24
    (6, 'Farinha de Mandioca', 12, 0), -- ID 25
    (6, 'Batata Palha',        10, 0), -- ID 26
    (3, 'Extrato de Tomate',   24, 1), -- ID 27
    (7, 'Pimenta do Reino',    4,  0), -- ID 28
    (7, 'Colorau',             4,  0), -- ID 29
    (7, 'Alho Batido',         5,  0), -- ID 30
    (7, 'Vinagre Alcool',      8,  0), -- ID 31
    (7, 'Molho de Tomate',     20, 1), -- ID 32
    (7, 'Louro em Po',         3,  0), -- ID 33
    (9, 'Suco de Laranja 1L',  18, 1), -- ID 34
    (9, 'Suco de Uva 1L',      18, 1), -- ID 35
    (9, 'Cha Gelado 1.5L',     15, 1), -- ID 36
    (9, 'Suco de Caju 1L',     20, 1), -- ID 37
    (9, 'Agua sem Gas 500ml',  40, 0), -- ID 38
    (3, 'Cebola Sacaria',      30, 1), -- ID 39
    (3, 'Alho Sacaria',        15, 1); -- ID 40

INSERT INTO marca (fkInsumo, fkFornecedor, nomeMarca) VALUES
    (1,  1, 'Italac'),          -- ID 1
    (2,  1, 'Polenghi'),        -- ID 2
    (3,  2, 'Seara'),           -- ID 3
    (4,  2, 'Friboi'),          -- ID 4
    (5,  3, 'Tio João'),        -- ID 5
    (6,  3, 'Camil'),           -- ID 6
    (7,  4, 'Cisne'),           -- ID 7
    (8,  4, 'Liza'),            -- ID 8
    (9,  5, 'Coca-Cola'),       -- ID 9
    (10, 5, 'Crystal'),         -- ID 10
    (11, 1, 'Piracanjuba'),     -- ID 11
    (12, 1, 'Aviacao'),         -- ID 12
    (13, 1, 'Vigor'),           -- ID 13
    (14, 1, 'MoCa'),            -- ID 14
    (15, 1, 'Tirolez'),         -- ID 15
    (16, 2, 'Sadia'),           -- ID 16
    (17, 2, 'Perdigao'),        -- ID 17
    (18, 2, 'Aurora'),          -- ID 18
    (19, 2, 'Seara Gourmet'),   -- ID 19
    (20, 2, 'Pif Paf'),         -- ID 20
    (21, 2, 'Copacol'),         -- ID 21
    (22, 3, 'Uniao'),           -- ID 22
    (23, 3, 'Dona Benta'),      -- ID 23
    (24, 3, 'Renata'),          -- ID 24
    (25, 3, 'Yoki'),            -- ID 25
    (26, 3, 'Quero'),           -- ID 26
    (27, 4, 'Elefante'),        -- ID 27
    (28, 4, 'Kitano'),          -- ID 28
    (29, 4, 'Sinha'),           -- ID 29
    (30, 4, 'Temperoni'),       -- ID 30
    (31, 4, 'Castelo'),         -- ID 31
    (32, 4, 'Pomarola'),        -- ID 32
    (33, 4, 'Bombay'),          -- ID 33
    (34, 5, 'Del Valle'),       -- ID 34
    (35, 5, 'Aurora Suco'),     -- ID 35
    (36, 5, 'Leao Fuze'),       -- ID 36
    (37, 5, 'Maguary'),         -- ID 37
    (38, 5, 'Minalba'),         -- ID 38
    (39, 3, 'Hortifruti Central'), -- ID 39
    (40, 3, 'Hortifruti Central'); -- ID 40

-- BLOCO DE LOTES 1: Primeiro lote para cada uma das 40 marcas
INSERT INTO lote (fkMarca, fkUsuario, precoUnit, unidadeMedida, quantidadeMedida, quantidadeTotal, dataEntrada, dataValidade) VALUES
    (1,  1, ROUND(3.50 + RAND() * 2.00, 2),  'L',  1,   FLOOR(50 + RAND() * 100), CURDATE(), DATE_ADD(CURDATE(), INTERVAL  5 DAY)),
    (2,  2, ROUND(35.00 + RAND() * 8.00, 2), 'kg', 1,   FLOOR(20 + RAND() * 50),  CURDATE(), DATE_ADD(CURDATE(), INTERVAL 15 DAY)),
    (3,  1, ROUND(11.00 + RAND() * 3.50, 2), 'kg', 2,   FLOOR(30 + RAND() * 60),  CURDATE(), DATE_ADD(CURDATE(), INTERVAL  3 DAY)),
    (4,  1, ROUND(27.00 + RAND() * 6.00, 2), 'kg', 1,   FLOOR(40 + RAND() * 80),  CURDATE(), DATE_ADD(CURDATE(), INTERVAL  7 DAY)),
    (5,  3, ROUND(24.90 + RAND() * 5.00, 2), 'kg', 5,   FLOOR(100 + RAND() * 200),CURDATE(), DATE_ADD(CURDATE(), INTERVAL 12 MONTH)),
    (6,  3, ROUND(6.50 + RAND() * 1.80, 2),  'kg', 1,   FLOOR(80 + RAND() * 150), CURDATE(), DATE_ADD(CURDATE(), INTERVAL 10 MONTH)),
    (7,  2, ROUND(2.50 + RAND() * 1.20, 2),  'kg', 1,   FLOOR(50 + RAND() * 100), CURDATE(), DATE_ADD(CURDATE(), INTERVAL 24 MONTH)),
    (8,  2, ROUND(7.50 + RAND() * 3.00, 2),  'ml', 900, FLOOR(60 + RAND() * 80),  CURDATE(), DATE_ADD(CURDATE(), INTERVAL 18 MONTH)),
    (9,  1, ROUND(8.50 + RAND() * 3.00, 2),  'L',  2,   FLOOR(150 + RAND() * 300),CURDATE(), DATE_ADD(CURDATE(), INTERVAL  6 MONTH)),
    (10, 3, ROUND(0.90 + RAND() * 0.80, 2),  'ml', 500, FLOOR(200 + RAND() * 500),CURDATE(), DATE_ADD(CURDATE(), INTERVAL  2 YEAR)),
    (11, 1, ROUND(4.00 + RAND() * 2.00, 2),  'g',  200, FLOOR(40 + RAND() * 60),  CURDATE(), DATE_ADD(CURDATE(), INTERVAL 20 DAY)),
    (12, 2, ROUND(18.00 + RAND() * 6.00, 2), 'g',  500, FLOOR(20 + RAND() * 40),  CURDATE(), DATE_ADD(CURDATE(), INTERVAL 40 DAY)),
    (13, 3, ROUND(6.00 + RAND() * 2.00, 2),  'g',  200, FLOOR(50 + RAND() * 80),  CURDATE(), DATE_ADD(CURDATE(), INTERVAL 25 DAY)),
    (14, 1, ROUND(6.50 + RAND() * 2.00, 2),  'g',  395, FLOOR(15 + RAND() * 30),  CURDATE(), DATE_ADD(CURDATE(), INTERVAL 35 DAY)),
    (15, 2, ROUND(32.00 + RAND() * 8.00, 2), 'kg', 1,   FLOOR(10 + RAND() * 20),  CURDATE(), DATE_ADD(CURDATE(), INTERVAL 28 DAY)),
    (16, 1, ROUND(12.00 + RAND() * 3.00, 2), 'kg', 1,   FLOOR(30 + RAND() * 50),  CURDATE(), DATE_ADD(CURDATE(), INTERVAL 4 DAY)),
    (17, 2, ROUND(11.00 + RAND() * 3.00, 2), 'kg', 1,   FLOOR(30 + RAND() * 50),  CURDATE(), DATE_ADD(CURDATE(), INTERVAL 5 DAY)),
    (18, 3, ROUND(23.00 + RAND() * 7.00, 2), 'kg', 1,   FLOOR(20 + RAND() * 40),  CURDATE(), DATE_ADD(CURDATE(), INTERVAL 9 DAY)),
    (19, 1, ROUND(17.00 + RAND() * 5.00, 2), 'kg', 1,   FLOOR(25 + RAND() * 45),  CURDATE(), DATE_ADD(CURDATE(), INTERVAL 12 DAY)),
    (20, 2, ROUND(28.00 + RAND() * 8.00, 2), 'kg', 1,   FLOOR(15 + RAND() * 30),  CURDATE(), DATE_ADD(CURDATE(), INTERVAL 20 DAY)),
    (21, 3, ROUND(31.00 + RAND() * 9.00, 2), 'kg', 1,   FLOOR(20 + RAND() * 35),  CURDATE(), DATE_ADD(CURDATE(), INTERVAL 10 DAY)),
    (22, 1, ROUND(4.50 + RAND() * 1.50, 2),  'kg', 1,   FLOOR(100 + RAND() * 150),CURDATE(), DATE_ADD(CURDATE(), INTERVAL 12 MONTH)),
    (23, 2, ROUND(5.00 + RAND() * 1.60, 2),  'kg', 1,   FLOOR(90 + RAND() * 140), CURDATE(), DATE_ADD(CURDATE(), INTERVAL 10 MONTH)),
    (24, 3, ROUND(3.20 + RAND() * 1.20, 2),  'g',  500, FLOOR(120 + RAND() * 200),CURDATE(), DATE_ADD(CURDATE(), INTERVAL 14 MONTH)),
    (25, 1, ROUND(8.00 + RAND() * 2.00, 2),  'g',  500, FLOOR(40 + RAND() * 70),  CURDATE(), DATE_ADD(CURDATE(), INTERVAL 9 MONTH)),
    (26, 2, ROUND(11.00 + RAND() * 3.00, 2), 'g',  500, FLOOR(35 + RAND() * 60),  CURDATE(), DATE_ADD(CURDATE(), INTERVAL 11 MONTH)),
    (27, 3, ROUND(2.80 + RAND() * 1.10, 2),  'g',  340, FLOOR(100 + RAND() * 150),CURDATE(), DATE_ADD(CURDATE(), INTERVAL 7 MONTH)),
    (28, 1, ROUND(6.00 + RAND() * 2.00, 2),  'g',  100, FLOOR(5 + RAND() * 10),   CURDATE(), DATE_ADD(CURDATE(), INTERVAL 24 MONTH)),
    (29, 2, ROUND(4.00 + RAND() * 2.00, 2),  'g',  100, FLOOR(20 + RAND() * 40),  CURDATE(), DATE_ADD(CURDATE(), INTERVAL 18 MONTH)),
    (30, 3, ROUND(15.00 + RAND() * 4.00, 2), 'g',  500, FLOOR(10 + RAND() * 15),  CURDATE(), DATE_ADD(CURDATE(), INTERVAL 20 MONTH)),
    (31, 1, ROUND(3.80 + RAND() * 1.30, 2),  'ml', 750, FLOOR(30 + RAND() * 50),  CURDATE(), DATE_ADD(CURDATE(), INTERVAL 16 MONTH)),
    (32, 2, ROUND(4.20 + RAND() * 1.40, 2),  'g',  340, FLOOR(40 + RAND() * 70),  CURDATE(), DATE_ADD(CURDATE(), INTERVAL 14 MONTH)),
    (33, 3, ROUND(3.00 + RAND() * 1.00, 2),  'g',  50,  FLOOR(25 + RAND() * 50),  CURDATE(), DATE_ADD(CURDATE(), INTERVAL 10 MONTH)),
    (34, 1, ROUND(7.50 + RAND() * 2.50, 2),  'L',  1,   FLOOR(80 + RAND() * 120), CURDATE(), DATE_ADD(CURDATE(), INTERVAL 5 MONTH)),
    (35, 2, ROUND(8.00 + RAND() * 2.70, 2),  'L',  1,   FLOOR(80 + RAND() * 110), CURDATE(), DATE_ADD(CURDATE(), INTERVAL 5 MONTH)),
    (36, 3, ROUND(6.20 + RAND() * 2.20, 2),  'L',  1.5, FLOOR(60 + RAND() * 90),  CURDATE(), DATE_ADD(CURDATE(), INTERVAL 4 MONTH)),
    (37, 1, ROUND(9.50 + RAND() * 3.50, 2),  'L',  1,   FLOOR(100 + RAND() * 150),CURDATE(), DATE_ADD(CURDATE(), INTERVAL 7 MONTH)),
    (38, 2, ROUND(2.10 + RAND() * 1.20, 2),  'ml', 500, FLOOR(120 + RAND() * 180),CURDATE(), DATE_ADD(CURDATE(), INTERVAL 2 YEAR)),
    (39, 3, ROUND(80.00 + RAND() * 10.00, 2),'kg', 20,  FLOOR(90 + RAND() * 130), CURDATE(), DATE_ADD(CURDATE(), INTERVAL  1 MONTH)),
    (40, 1, ROUND(120.00 + RAND() * 20.0, 2),'kg', 10,  FLOOR(40 + RAND() * 80),  CURDATE(), DATE_ADD(CURDATE(), INTERVAL  2 MONTH));

-- BLOCO DE LOTES 2: Segundo lote para cada uma das 40 marcas
INSERT INTO lote (fkMarca, fkUsuario, precoUnit, unidadeMedida, quantidadeMedida, quantidadeTotal, dataEntrada, dataValidade) VALUES
    (1,  2, ROUND(3.40 + RAND() * 2.00, 2),  'L',  1,   FLOOR(30 + RAND() * 80),  DATE_SUB(CURDATE(), INTERVAL 2 DAY), DATE_ADD(CURDATE(), INTERVAL 3 DAY)),
    (2,  3, ROUND(36.00 + RAND() * 5.00, 2), 'kg', 1,   FLOOR(15 + RAND() * 40),  DATE_SUB(CURDATE(), INTERVAL 1 DAY), DATE_ADD(CURDATE(), INTERVAL 10 DAY)),
    (3,  2, ROUND(10.00 + RAND() * 3.00, 2), 'kg', 2,   FLOOR(20 + RAND() * 40),  DATE_SUB(CURDATE(), INTERVAL 5 DAY), DATE_SUB(CURDATE(), INTERVAL 1 DAY)),
    (4,  3, ROUND(26.50 + RAND() * 5.00, 2), 'kg', 1,   FLOOR(30 + RAND() * 60),  DATE_SUB(CURDATE(), INTERVAL 3 DAY), DATE_ADD(CURDATE(), INTERVAL 4 DAY)),
    (5,  1, ROUND(25.20 + RAND() * 4.00, 2), 'kg', 5,   FLOOR(80 + RAND() * 120), DATE_SUB(CURDATE(), INTERVAL 20 DAY), DATE_ADD(CURDATE(), INTERVAL 11 MONTH)),
    (6,  1, ROUND(6.10 + RAND() * 1.50, 2),  'kg', 1,   FLOOR(70 + RAND() * 120), DATE_SUB(CURDATE(), INTERVAL 15 DAY), DATE_ADD(CURDATE(), INTERVAL 9 MONTH)),
    (7,  3, ROUND(2.40 + RAND() * 1.00, 2),  'kg', 1,   FLOOR(40 + RAND() * 80),  DATE_SUB(CURDATE(), INTERVAL 30 DAY), DATE_ADD(CURDATE(), INTERVAL 23 MONTH)),
    (8,  1, ROUND(7.20 + RAND() * 2.00, 2),  'ml', 900, FLOOR(50 + RAND() * 70),  DATE_SUB(CURDATE(), INTERVAL 10 DAY), DATE_ADD(CURDATE(), INTERVAL 17 MONTH)),
    (9,  2, ROUND(8.20 + RAND() * 2.00, 2),  'L',  2,   FLOOR(100 + RAND() * 200),DATE_SUB(CURDATE(), INTERVAL 4 DAY), DATE_ADD(CURDATE(), INTERVAL 5 MONTH)),
    (10, 1, ROUND(0.85 + RAND() * 0.50, 2),  'ml', 500, FLOOR(150 + RAND() * 350),DATE_SUB(CURDATE(), INTERVAL 8 DAY), DATE_ADD(CURDATE(), INTERVAL 23 MONTH)),
    (11, 2, ROUND(4.10 + RAND() * 1.50, 2),  'g',  200, FLOOR(30 + RAND() * 50),  DATE_SUB(CURDATE(), INTERVAL 2 DAY), DATE_ADD(CURDATE(), INTERVAL 18 DAY)),
    (12, 3, ROUND(17.50 + RAND() * 5.00, 2), 'g',  500, FLOOR(15 + RAND() * 30),  DATE_SUB(CURDATE(), INTERVAL 4 DAY), DATE_ADD(CURDATE(), INTERVAL 36 DAY)),
    (13, 1, ROUND(5.80 + RAND() * 1.50, 2),  'g',  200, FLOOR(40 + RAND() * 70),  DATE_SUB(CURDATE(), INTERVAL 3 DAY), DATE_ADD(CURDATE(), INTERVAL 22 DAY)),
    (14, 3, ROUND(6.80 + RAND() * 1.50, 2),  'g',  395, FLOOR(10 + RAND() * 25),  DATE_SUB(CURDATE(), INTERVAL 1 DAY), DATE_ADD(CURDATE(), INTERVAL 34 DAY)),
    (15, 1, ROUND(31.00 + RAND() * 6.00, 2), 'kg', 1,   FLOOR(8 + RAND() * 15),   DATE_SUB(CURDATE(), INTERVAL 6 DAY), DATE_ADD(CURDATE(), INTERVAL 22 DAY)),
    (16, 2, ROUND(11.50 + RAND() * 2.50, 2), 'kg', 1,   FLOOR(20 + RAND() * 45),  DATE_SUB(CURDATE(), INTERVAL 2 DAY), DATE_ADD(CURDATE(), INTERVAL 2 DAY)),
    (17, 3, ROUND(10.50 + RAND() * 2.50, 2), 'kg', 1,   FLOOR(20 + RAND() * 40),  DATE_SUB(CURDATE(), INTERVAL 8 DAY), DATE_ADD(CURDATE(), INTERVAL 2 DAY)),
    (18, 1, ROUND(22.00 + RAND() * 5.00, 2), 'kg', 1,   FLOOR(15 + RAND() * 35),  DATE_SUB(CURDATE(), INTERVAL 3 DAY), DATE_ADD(CURDATE(), INTERVAL 6 DAY)),
    (19, 2, ROUND(16.50 + RAND() * 4.00, 2), 'kg', 1,   FLOOR(20 + RAND() * 35),  DATE_SUB(CURDATE(), INTERVAL 4 DAY), DATE_ADD(CURDATE(), INTERVAL 8 DAY)),
    (20, 3, ROUND(27.00 + RAND() * 6.00, 2), 'kg', 1,   FLOOR(10 + RAND() * 25),  DATE_SUB(CURDATE(), INTERVAL 5 DAY), DATE_ADD(CURDATE(), INTERVAL 15 DAY)),
    (21, 1, ROUND(30.00 + RAND() * 7.00, 2), 'kg', 1,   FLOOR(15 + RAND() * 30),  DATE_SUB(CURDATE(), INTERVAL 2 DAY), DATE_ADD(CURDATE(), INTERVAL 8 DAY)),
    (22, 2, ROUND(4.30 + RAND() * 1.00, 2),  'kg', 1,   FLOOR(80 + RAND() * 120), DATE_SUB(CURDATE(), INTERVAL 12 DAY), DATE_ADD(CURDATE(), INTERVAL 11 MONTH)),
    (23, 3, ROUND(4.80 + RAND() * 1.20, 2),  'kg', 1,   FLOOR(70 + RAND() * 110), DATE_SUB(CURDATE(), INTERVAL 18 DAY), DATE_ADD(CURDATE(), INTERVAL 9 MONTH)),
    (24, 1, ROUND(3.00 + RAND() * 1.00, 2),  'g',  500, FLOOR(100 + RAND() * 150),DATE_SUB(CURDATE(), INTERVAL 10 DAY), DATE_ADD(CURDATE(), INTERVAL 13 MONTH)),
    (25, 2, ROUND(7.50 + RAND() * 1.50, 2),  'g',  500, FLOOR(30 + RAND() * 50),  DATE_SUB(CURDATE(), INTERVAL 14 DAY), DATE_ADD(CURDATE(), INTERVAL 8 MONTH)),
    (26, 3, ROUND(10.50 + RAND() * 2.00, 2), 'g',  500, FLOOR(25 + RAND() * 50),  DATE_SUB(CURDATE(), INTERVAL 20 DAY), DATE_ADD(CURDATE(), INTERVAL 10 MONTH)),
    (27, 1, ROUND(2.60 + RAND() * 0.90, 2),  'g',  340, FLOOR(80 + RAND() * 120), DATE_SUB(CURDATE(), INTERVAL 5 DAY),  DATE_ADD(CURDATE(), INTERVAL 6 MONTH)),
    (28, 2, ROUND(5.80 + RAND() * 1.00, 2),  'g',  100, FLOOR(4 + RAND() * 6),    DATE_SUB(CURDATE(), INTERVAL 45 DAY), DATE_ADD(CURDATE(), INTERVAL 22 MONTH)),
    (29, 3, ROUND(3.80 + RAND() * 1.50, 2),  'g',  100, FLOOR(15 + RAND() * 30),  DATE_SUB(CURDATE(), INTERVAL 15 DAY), DATE_ADD(CURDATE(), INTERVAL 17 MONTH)),
    (30, 1, ROUND(14.00 + RAND() * 3.00, 2), 'g',  500, FLOOR(8 + RAND() * 12),   DATE_SUB(CURDATE(), INTERVAL 8 DAY),  DATE_ADD(CURDATE(), INTERVAL 19 MONTH)),
    (31, 2, ROUND(3.60 + RAND() * 1.00, 2),  'ml', 750, FLOOR(20 + RAND() * 40),  DATE_SUB(CURDATE(), INTERVAL 12 DAY), DATE_ADD(CURDATE(), INTERVAL 15 MONTH)),
    (32, 3, ROUND(4.00 + RAND() * 1.00, 2),  'g',  340, FLOOR(30 + RAND() * 50),  DATE_SUB(CURDATE(), INTERVAL 6 DAY),  DATE_ADD(CURDATE(), INTERVAL 13 MONTH)),
    (33, 1, ROUND(2.50 + RAND() * 1.00, 2),  'g',  50,  FLOOR(15 + RAND() * 35),  DATE_SUB(CURDATE(), INTERVAL 25 DAY), DATE_ADD(CURDATE(), INTERVAL 9 MONTH)),
    (34, 2, ROUND(7.00 + RAND() * 2.00, 2),  'L',  1,   FLOOR(60 + RAND() * 100), DATE_SUB(CURDATE(), INTERVAL 4 DAY),  DATE_ADD(CURDATE(), INTERVAL 4 MONTH)),
    (35, 3, ROUND(7.60 + RAND() * 2.00, 2),  'L',  1,   FLOOR(60 + RAND() * 90),  DATE_SUB(CURDATE(), INTERVAL 5 DAY),  DATE_ADD(CURDATE(), INTERVAL 4 MONTH)),
    (36, 1, ROUND(5.90 + RAND() * 1.50, 2),  'L',  1.5, FLOOR(40 + RAND() * 70),  DATE_SUB(CURDATE(), INTERVAL 10 DAY), DATE_ADD(CURDATE(), INTERVAL 3 MONTH)),
    (37, 2, ROUND(9.00 + RAND() * 2.50, 2),  'L',  1,   FLOOR(80 + RAND() * 120), DATE_SUB(CURDATE(), INTERVAL 3 DAY),  DATE_ADD(CURDATE(), INTERVAL 6 MONTH)),
    (38, 3, ROUND(2.00 + RAND() * 0.90, 2),  'ml', 500, FLOOR(100 + RAND() * 140),DATE_SUB(CURDATE(), INTERVAL 6 DAY),  DATE_ADD(CURDATE(), INTERVAL 23 MONTH)),
    (39, 1, ROUND(78.50 + RAND() * 8.00, 2), 'kg', 20,  FLOOR(60 + RAND() * 100), DATE_SUB(CURDATE(), INTERVAL 4 DAY),  DATE_ADD(CURDATE(), INTERVAL 20 DAY)),
    (40, 2, ROUND(110.00 + RAND() * 15.0, 2),'kg', 10,  FLOOR(30 + RAND() * 60),  DATE_SUB(CURDATE(), INTERVAL 5 DAY),  DATE_ADD(CURDATE(), INTERVAL 45 DAY));

-- BLOCO DE LOTES 3: Terceiro lote para produtos de altíssima saída em restaurantes
INSERT INTO lote (fkMarca, fkUsuario, precoUnit, unidadeMedida, quantidadeMedida, quantidadeTotal, dataEntrada, dataValidade) VALUES
    (5,  1, ROUND(25.30 + RAND() * 3.00, 2), 'kg', 5,   FLOOR(90 + RAND() * 110), CURDATE(), DATE_ADD(CURDATE(), INTERVAL 14 MONTH)),
    (6,  2, ROUND(6.40 + RAND() * 1.00, 2),  'kg', 1,   FLOOR(80 + RAND() * 110), CURDATE(), DATE_ADD(CURDATE(), INTERVAL 11 MONTH)),
    (9,  3, ROUND(8.60 + RAND() * 1.50, 2),  'L',  2,   FLOOR(120 + RAND() * 180),CURDATE(), DATE_ADD(CURDATE(), INTERVAL 7 MONTH)),
    (16, 1, ROUND(12.20 + RAND() * 2.00, 2), 'kg', 1,   FLOOR(25 + RAND() * 40),  CURDATE(), DATE_ADD(CURDATE(), INTERVAL 6 DAY)),
    (24, 2, ROUND(3.30 + RAND() * 1.00, 2),  'g',  500, FLOOR(110 + RAND() * 160),CURDATE(), DATE_ADD(CURDATE(), INTERVAL 15 MONTH)),
    (39, 3, ROUND(82.90 + RAND() * 5.00, 2), 'kg', 20,  FLOOR(80 + RAND() * 120), CURDATE(), DATE_ADD(CURDATE(), INTERVAL 25 DAY));


INSERT INTO boleto (descricao, categoria, pago, dataVencimento, dataPagamento, valor, fkFornecedor) VALUES
    ('Boleto energia - Janeiro',         'Contas Consumo',         1, DATE_ADD(MAKEDATE(YEAR(CURDATE()), 1), INTERVAL   9 DAY), DATE_SUB(DATE_ADD(MAKEDATE(YEAR(CURDATE()), 1), INTERVAL   9 DAY), INTERVAL FLOOR(1 + RAND() * 4) DAY), ROUND(400 + RAND() * 150, 2), FLOOR(RAND() * 5) + 1),
    ('Boleto fornecedor - Janeiro',      'Boletos Fornecedores',   0, DATE_ADD(MAKEDATE(YEAR(CURDATE()), 1), INTERVAL  19 DAY), '1970-01-01 00:00:00',                                                                                  ROUND(700 + RAND() * 200, 2), FLOOR(RAND() * 5) + 1),
    ('Boleto energia - Fevereiro',       'Contas Consumo',         1, DATE_ADD(MAKEDATE(YEAR(CURDATE()), 1), INTERVAL  40 DAY), DATE_SUB(DATE_ADD(MAKEDATE(YEAR(CURDATE()), 1), INTERVAL  40 DAY), INTERVAL FLOOR(1 + RAND() * 5) DAY), ROUND(420 + RAND() * 150, 2), FLOOR(RAND() * 5) + 1),
    ('Boleto fornecedor - Fevereiro',    'Boletos Fornecedores',   0, DATE_ADD(MAKEDATE(YEAR(CURDATE()), 1), INTERVAL  48 DAY), '1970-01-01 00:00:00',                                                                                  ROUND(720 + RAND() * 200, 2), FLOOR(RAND() * 5) + 1),
    ('Boleto energia - Marco',           'Contas Consumo',         1, DATE_ADD(MAKEDATE(YEAR(CURDATE()), 1), INTERVAL  68 DAY), DATE_SUB(DATE_ADD(MAKEDATE(YEAR(CURDATE()), 1), INTERVAL  68 DAY), INTERVAL FLOOR(1 + RAND() * 4) DAY), ROUND(440 + RAND() * 150, 2), FLOOR(RAND() * 5) + 1),
    ('Boleto fornecedor - Marco',        'Boletos Fornecedores',   0, DATE_ADD(MAKEDATE(YEAR(CURDATE()), 1), INTERVAL  78 DAY), '1970-01-01 00:00:00',                                                                                  ROUND(750 + RAND() * 200, 2), FLOOR(RAND() * 5) + 1),
    ('Boleto energia - Abril',           'Contas Consumo',         1, DATE_ADD(MAKEDATE(YEAR(CURDATE()), 1), INTERVAL  99 DAY), DATE_SUB(DATE_ADD(MAKEDATE(YEAR(CURDATE()), 1), INTERVAL  99 DAY), INTERVAL FLOOR(1 + RAND() * 3) DAY), ROUND(400 + RAND() * 150, 2), FLOOR(RAND() * 5) + 1),
    ('Boleto fornecedor - Abril',        'Boletos Fornecedores',   0, DATE_ADD(MAKEDATE(YEAR(CURDATE()), 1), INTERVAL 109 DAY), '1970-01-01 00:00:00',                                                                                  ROUND(770 + RAND() * 200, 2), FLOOR(RAND() * 5) + 1),
    ('Boleto energia - Maio',            'Contas Consumo',         1, DATE_ADD(MAKEDATE(YEAR(CURDATE()), 1), INTERVAL 129 DAY), DATE_SUB(DATE_ADD(MAKEDATE(YEAR(CURDATE()), 1), INTERVAL 129 DAY), INTERVAL FLOOR(1 + RAND() * 4) DAY), ROUND(430 + RAND() * 150, 2), FLOOR(RAND() * 5) + 1),
    ('Boleto fornecedor - Maio',         'Boletos Fornecedores',   0, DATE_ADD(MAKEDATE(YEAR(CURDATE()), 1), INTERVAL 140 DAY), '1970-01-01 00:00:00',                                                                                  ROUND(790 + RAND() * 200, 2), FLOOR(RAND() * 5) + 1),
    ('Boleto energia - Junho',           'Contas Consumo',         1, DATE_ADD(MAKEDATE(YEAR(CURDATE()), 1), INTERVAL 160 DAY), DATE_SUB(DATE_ADD(MAKEDATE(YEAR(CURDATE()), 1), INTERVAL 160 DAY), INTERVAL FLOOR(1 + RAND() * 5) DAY), ROUND(450 + RAND() * 150, 2), FLOOR(RAND() * 5) + 1),
    ('Boleto fornecedor - Junho',        'Boletos Fornecedores',   0, DATE_ADD(MAKEDATE(YEAR(CURDATE()), 1), INTERVAL 170 DAY), '1970-01-01 00:00:00',                                                                                  ROUND(800 + RAND() * 200, 2), FLOOR(RAND() * 5) + 1),
    ('Boleto energia - Julho',           'Contas Consumo',         1, DATE_ADD(MAKEDATE(YEAR(CURDATE()), 1), INTERVAL 190 DAY), DATE_SUB(DATE_ADD(MAKEDATE(YEAR(CURDATE()), 1), INTERVAL 190 DAY), INTERVAL FLOOR(1 + RAND() * 4) DAY), ROUND(460 + RAND() * 150, 2), FLOOR(RAND() * 5) + 1),
    ('Boleto fornecedor - Julho',        'Boletos Fornecedores',   0, DATE_ADD(MAKEDATE(YEAR(CURDATE()), 1), INTERVAL 201 DAY), '1970-01-01 00:00:00',                                                                                  ROUND(810 + RAND() * 200, 2), FLOOR(RAND() * 5) + 1),
    ('Boleto energia - Agosto',          'Contas Consumo',         1, DATE_ADD(MAKEDATE(YEAR(CURDATE()), 1), INTERVAL 221 DAY), DATE_SUB(DATE_ADD(MAKEDATE(YEAR(CURDATE()), 1), INTERVAL 221 DAY), INTERVAL FLOOR(1 + RAND() * 4) DAY), ROUND(470 + RAND() * 150, 2), FLOOR(RAND() * 5) + 1),
    ('Boleto fornecedor - Agosto',       'Boletos Fornecedores',   0, DATE_ADD(MAKEDATE(YEAR(CURDATE()), 1), INTERVAL 231 DAY), '1970-01-01 00:00:00',                                                                                  ROUND(820 + RAND() * 200, 2), FLOOR(RAND() * 5) + 1),
    ('Boleto energia - Setembro',        'Contas Consumo',         1, DATE_ADD(MAKEDATE(YEAR(CURDATE()), 1), INTERVAL 252 DAY), DATE_SUB(DATE_ADD(MAKEDATE(YEAR(CURDATE()), 1), INTERVAL 252 DAY), INTERVAL FLOOR(1 + RAND() * 4) DAY), ROUND(480 + RAND() * 150, 2), FLOOR(RAND() * 5) + 1),
    ('Boleto fornecedor - Setembro',     'Boletos Fornecedores',   0, DATE_ADD(MAKEDATE(YEAR(CURDATE()), 1), INTERVAL 262 DAY), '1970-01-01 00:00:00',                                                                                  ROUND(830 + RAND() * 200, 2), FLOOR(RAND() * 5) + 1),
    ('Boleto energia - Outubro',         'Contas Consumo',         1, DATE_ADD(MAKEDATE(YEAR(CURDATE()), 1), INTERVAL 282 DAY), DATE_SUB(DATE_ADD(MAKEDATE(YEAR(CURDATE()), 1), INTERVAL 282 DAY), INTERVAL FLOOR(1 + RAND() * 5) DAY), ROUND(490 + RAND() * 150, 2), FLOOR(RAND() * 5) + 1),
    ('Boleto fornecedor - Outubro',      'Boletos Fornecedores',   0, DATE_ADD(MAKEDATE(YEAR(CURDATE()), 1), INTERVAL 292 DAY), '1970-01-01 00:00:00',                                                                                  ROUND(850 + RAND() * 200, 2), FLOOR(RAND() * 5) + 1),
    ('Boleto energia - Novembro',        'Contas Consumo',         1, DATE_ADD(MAKEDATE(YEAR(CURDATE()), 1), INTERVAL 313 DAY), DATE_SUB(DATE_ADD(MAKEDATE(YEAR(CURDATE()), 1), INTERVAL 313 DAY), INTERVAL FLOOR(1 + RAND() * 4) DAY), ROUND(500 + RAND() * 150, 2), FLOOR(RAND() * 5) + 1),
    ('Boleto fornecedor - Novembro',     'Boletos Fornecedores',   0, DATE_ADD(MAKEDATE(YEAR(CURDATE()), 1), INTERVAL 323 DAY), '1970-01-01 00:00:00',                                                                                  ROUND(860 + RAND() * 200, 2), FLOOR(RAND() * 5) + 1),
    ('Boleto energia - Dezembro',        'Contas Consumo',         1, DATE_ADD(MAKEDATE(YEAR(CURDATE()), 1), INTERVAL 343 DAY), DATE_SUB(DATE_ADD(MAKEDATE(YEAR(CURDATE()), 1), INTERVAL 343 DAY), INTERVAL FLOOR(1 + RAND() * 4) DAY), ROUND(510 + RAND() * 150, 2), FLOOR(RAND() * 5) + 1),
    ('Boleto fornecedor - Dezembro',     'Boletos Fornecedores',   0, DATE_ADD(MAKEDATE(YEAR(CURDATE()), 1), INTERVAL 353 DAY), '1970-01-01 00:00:00',                                                                                  ROUND(880 + RAND() * 200, 2), FLOOR(RAND() * 5) + 1);

INSERT INTO cliente (nome, telefone, cep, logradouro, bairro) VALUES
    (CASE FLOOR(RAND() * 5) WHEN 0 THEN 'Joao Pedro Lima' WHEN 1 THEN 'Anselmo Silva Santos' WHEN 2 THEN 'João Oliveira' WHEN 3 THEN 'Carlos da Costa' ELSE 'Felipe Ferreira' END, 
     CONCAT('(11) 9', LPAD(FLOOR(8000 + RAND() * 2000), 4, '0'), '-', LPAD(FLOOR(RAND() * 10000), 4, '0')), 
     CONCAT(LPAD(FLOOR(RAND() * 99999), 5, '0'), '-', LPAD(FLOOR(RAND() * 999), 3, '0')), 'Rua das Palmeiras, 120', 'Centro'),
    (CASE FLOOR(RAND() * 5) WHEN 0 THEN 'Mariana Costa Alves' WHEN 1 THEN 'Clara Silva' WHEN 2 THEN 'Mariana Oliveira' WHEN 3 THEN 'Beatriz Santos' ELSE 'Mariana Pereira' END, 
     CONCAT('(11) 9', LPAD(FLOOR(8000 + RAND() * 2000), 4, '0'), '-', LPAD(FLOOR(RAND() * 10000), 4, '0')), 
     CONCAT(LPAD(FLOOR(RAND() * 99999), 5, '0'), '-', LPAD(FLOOR(RAND() * 999), 3, '0')), 'Av. Paulista, 1500', 'Bela Vista'),
    (CASE FLOOR(RAND() * 5) WHEN 0 THEN 'Rafael Souza Martins' WHEN 1 THEN 'Rafael Costa' WHEN 2 THEN 'Lucas Silva' WHEN 3 THEN 'Thiago Oliveira' ELSE 'Rafael Santos' END, 
     CONCAT('(11) 9', LPAD(FLOOR(8000 + RAND() * 2000), 4, '0'), '-', LPAD(FLOOR(RAND() * 10000), 4, '0')), 
     CONCAT(LPAD(FLOOR(RAND() * 99999), 5, '0'), '-', LPAD(FLOOR(RAND() * 999), 3, '0')), 'Rua do Carmo, 45', 'Mooca'),
    (CASE FLOOR(RAND() * 5) WHEN 0 THEN 'Patricia Nunes Rocha' WHEN 1 THEN 'Patricia Silva' WHEN 2 THEN 'Fernanda Costa' WHEN 3 THEN 'Patricia Santos' ELSE 'Aline Oliveira' END, 
     CONCAT('(11) 9', LPAD(FLOOR(8000 + RAND() * 2000), 4, '0'), '-', LPAD(FLOOR(RAND() * 10000), 4, '0')), 
     CONCAT(LPAD(FLOOR(RAND() * 99999), 5, '0'), '-', LPAD(FLOOR(RAND() * 999), 3, '0')), 'Rua Voluntarios, 300', 'Santana'),
    (CASE FLOOR(RAND() * 5) WHEN 0 THEN 'Bruno Henrique Santos' WHEN 1 THEN 'Bruno Silva' WHEN 2 THEN 'Rodrigo Costa' WHEN 3 THEN 'Bruno Oliveira' ELSE 'Ricardo Pereira' END, 
     CONCAT('(11) 9', LPAD(FLOOR(8000 + RAND() * 2000), 4, '0'), '-', LPAD(FLOOR(RAND() * 10000), 4, '0')), 
     CONCAT(LPAD(FLOOR(RAND() * 99999), 5, '0'), '-', LPAD(FLOOR(RAND() * 999), 3, '0')), 'Rua Clovis, 88', 'Lapa');

INSERT INTO divida (valor, dataCompra, dataPagamento, pedido, pago, fkCliente) VALUES
    (ROUND(50 + RAND() * 100, 2),  DATE_SUB(CURDATE(), INTERVAL FLOOR(10 + RAND() * 30) DAY), DATE_SUB(CURDATE(), INTERVAL FLOOR(5 + RAND() * 20) DAY), CONCAT('PF-', LPAD(FLOOR(RAND() * 9999), 4, '0')), 1, 1),
    (ROUND(20 + RAND() * 80, 2),   DATE_SUB(CURDATE(), INTERVAL FLOOR(2 + RAND() * 15) DAY),  '1970-01-01 00:00:00',                                    CONCAT('PF-', LPAD(FLOOR(RAND() * 9999), 4, '0')), 0, 1),
    (ROUND(80 + RAND() * 120, 2),  DATE_SUB(CURDATE(), INTERVAL FLOOR(8 + RAND() * 25) DAY),  DATE_SUB(CURDATE(), INTERVAL FLOOR(2 + RAND() * 15) DAY), CONCAT('PF-', LPAD(FLOOR(RAND() * 9999), 4, '0')), 1, 2),
    (ROUND(30 + RAND() * 80, 2),   DATE_SUB(CURDATE(), INTERVAL FLOOR(1 + RAND() * 10) DAY),  DATE_SUB(CURDATE(), INTERVAL FLOOR(1 + RAND() * 5) DAY),  CONCAT('PF-', LPAD(FLOOR(RAND() * 9999), 4, '0')), 1, 2),
    (ROUND(100 + RAND() * 150, 2), DATE_SUB(CURDATE(), INTERVAL FLOOR(30 + RAND() * 60) DAY), '1970-01-01 00:00:00',                                    CONCAT('PF-', LPAD(FLOOR(RAND() * 9999), 4, '0')), 0, 3),
    (ROUND(25 + RAND() * 75, 2),   DATE_SUB(CURDATE(), INTERVAL FLOOR(1 + RAND() * 10) DAY),  '1970-01-01 00:00:00',                                    CONCAT('PF-', LPAD(FLOOR(RAND() * 9999), 4, '0')), 0, 3),
    (ROUND(60 + RAND() * 100, 2),  DATE_SUB(CURDATE(), INTERVAL FLOOR(5 + RAND() * 20) DAY),  DATE_SUB(CURDATE(), INTERVAL FLOOR(2 + RAND() * 15) DAY), CONCAT('PF-', LPAD(FLOOR(RAND() * 9999), 4, '0')), 1, 4),
    (ROUND(70 + RAND() * 120, 2),  DATE_SUB(CURDATE(), INTERVAL FLOOR(3 + RAND() * 15) DAY),  '1970-01-01 00:00:00',                                    CONCAT('PF-', LPAD(FLOOR(RAND() * 9999), 4, '0')), 0, 4),
    (ROUND(130 + RAND() * 180, 2), DATE_SUB(CURDATE(), INTERVAL FLOOR(40 + RAND() * 80) DAY), '1970-01-01 00:00:00',                                    CONCAT('PF-', LPAD(FLOOR(RAND() * 9999), 4, '0')), 0, 5),
    (ROUND(40 + RAND() * 100, 2),  DATE_SUB(CURDATE(), INTERVAL FLOOR(5 + RAND() * 20) DAY),  DATE_SUB(CURDATE(), INTERVAL FLOOR(2 + RAND() * 10) DAY), CONCAT('PF-', LPAD(FLOOR(RAND() * 9999), 4, '0')), 1, 5);