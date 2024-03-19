CREATE TABLE situacao_ponto (
    id_situacao_ponto SERIAL PRIMARY KEY,
    descricao VARCHAR(50) NOT NULL
);

CREATE TABLE funcionario (
    id_funcionario SERIAL PRIMARY KEY,
    matricula VARCHAR(20) UNIQUE NOT NULL,
    email VARCHAR(100) UNIQUE NOT NULL
);

CREATE TABLE ponto (
    id_ponto SERIAL PRIMARY KEY,
    id_funcionario INTEGER REFERENCES funcionario(id_funcionario),
    id_situacao_ponto INTEGER REFERENCES situacao_ponto(id_situacao_ponto),
    data DATE NOT NULL,
    horas_trabalhadas DECIMAL(5,2) NOT NULL
);

CREATE TABLE periodo_ponto (
    id_ponto INTEGER PRIMARY KEY REFERENCES ponto(id_ponto),
    hora_entrada TIME NOT NULL,
    hora_saida TIME NOT NULL,
    horas_periodo DECIMAL(5,2) NOT NULL
);
