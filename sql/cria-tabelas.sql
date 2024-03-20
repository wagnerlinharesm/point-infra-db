CREATE TABLE situacao_ponto (
    id_situacao_ponto SERIAL PRIMARY KEY,
    situacao VARCHAR(50) NOT NULL
);

CREATE TABLE funcionario (
    id_funcionario VARCHAR(20) PRIMARY KEY,
    email VARCHAR(100) UNIQUE NOT NULL
);

CREATE TABLE ponto (
    id_ponto SERIAL PRIMARY KEY,
    id_funcionario VARCHAR(20) REFERENCES funcionario(id_funcionario),
    id_situacao_ponto INTEGER REFERENCES situacao_ponto(id_situacao_ponto),
    data DATE NOT NULL,
    horas_trabalhadas TIME NOT NULL
);

CREATE TABLE periodo_ponto (
    id_periodo_ponto SERIAL PRIMARY KEY,
    id_ponto INTEGER REFERENCES ponto(id_ponto),
    hora_entrada TIME NOT NULL,
    hora_saida TIME,
    horas_periodo TIME NOT NULL
);