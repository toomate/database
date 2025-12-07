
drop user if exists 'toomate_user'@'%';
create user 'toomate_user'@'%' identified by 'toomate_password';
grant all on toomate.* to 'toomate_user'@'%';

flush privileges;

drop database if exists toomate;
create database if not exists toomate;
USE toomate;

/*
*/
CREATE TABLE usuario (
    idUsuario INT PRIMARY KEY AUTO_INCREMENT,
    nome VARCHAR(45),
    senha CHAR(64),
    administrador TINYINT
);

CREATE TABLE categoria (
    idCategoria INT PRIMARY KEY AUTO_INCREMENT,
    nome VARCHAR(45),
    rotatividade TINYINT
);

CREATE TABLE insumo (
    idInsumo INT PRIMARY KEY AUTO_INCREMENT,
    fkCategoria INT,
    nome VARCHAR(45),
    qtdMinima INT,
    unidadeMedida VARCHAR(20),
    CONSTRAINT fk_insumo_categoria FOREIGN KEY (fkCategoria) REFERENCES categoria(idCategoria)
);

CREATE TABLE rotina (
    idRotina INT PRIMARY KEY AUTO_INCREMENT,
    titulo VARCHAR(45),
    quantidadeMedida INT
);

CREATE TABLE rotinaInsumo (
    id INT PRIMARY KEY AUTO_INCREMENT,
    idRotina INT,
    idInsumo INT,
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
    quantidadeMedida DOUBLE,
    dateEntrada DATE,
    fkMarca INT,
    fkUsuario INT,
    CONSTRAINT fk_lote_marca FOREIGN KEY (fkMarca) REFERENCES marca(idMarca),
    CONSTRAINT fk_lote_usuario FOREIGN KEY (fkUsuario) REFERENCES usuario(idUsuario)
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
    l.quantidadeMedida AS QtdAtual,
    DATEDIFF(l.dataValidade, CURDATE()) AS DiasParaVencer
FROM lote l
JOIN marca m ON l.fkMarca = m.idMarca
JOIN insumo i ON m.fkInsumo = i.idInsumo
WHERE l.dataValidade <= DATE_ADD(CURDATE(), INTERVAL 7 DAY);


-- 2. KPI: Itens com estoque abaixo ou igual ao mínimo
CREATE VIEW vw_kpi_estoque_baixo AS
SELECT 
    i.nome AS Insumo,
    SUM(l.quantidadeMedida) AS EstoqueTotal,
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
    COALESCE(SUM(l.quantidadeMedida), 0) AS EstoqueAtual,
    i.qtdMinima AS EstoqueMinimo,
    CASE 
        WHEN COALESCE(SUM(l.quantidadeMedida), 0) < i.qtdMinima THEN 'Repor Urgente'
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
    SUM(l.quantidadeMedida) AS EstoqueAtual,
    i.qtdMinima,
    (SUM(l.quantidadeMedida) - i.qtdMinima) AS MargemSeguranca
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
    l.quantidadeMedida AS QtdNoLote,
    l.dataValidade,
    DATEDIFF(l.dataValidade, CURDATE()) AS DiasRestantes
FROM lote l
JOIN marca m ON l.fkMarca = m.idMarca
JOIN insumo i ON m.fkInsumo = i.idInsumo
WHERE l.dataValidade > CURDATE() -- Ainda não venceu
  AND DATEDIFF(l.dataValidade, CURDATE()) <= 5 -- Vence em 5 dias ou menos
ORDER BY l.quantidadeMedida DESC -- Prioriza os que tem maior quantidade em risco
LIMIT 1;


-- 15. Financeiro Estoque: Valor total de itens cadastrados na semana atual
CREATE VIEW vw_total_entrada_estoque_semana AS
SELECT 
    COALESCE(SUM(l.precoUnit * l.quantidadeMedida), 0) AS ValorTotalEntradas
FROM lote l
WHERE YEARWEEK(l.dateEntrada, 1) = YEARWEEK(CURDATE(), 1);


-- 16. Perda: Valor total de itens perdidos (Vencidos e ainda em estoque)
CREATE VIEW vw_total_perda_validade AS
SELECT 
    COALESCE(SUM(l.precoUnit * l.quantidadeMedida), 0) AS ValorTotalPerda
FROM lote l
WHERE l.dataValidade < CURDATE();