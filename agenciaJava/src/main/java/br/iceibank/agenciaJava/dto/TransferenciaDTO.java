package br.iceibank.agenciaJava.dto;

public class TransferenciaDTO {
    private int idOrigem;
    private int idDestino;
    private double valor;

    public int getIdOrigem() { return idOrigem; }
    public void setIdOrigem(int idOrigem) { this.idOrigem = idOrigem; }
    public int getIdDestino() { return idDestino; }
    public void setIdDestino(int idDestino) { this.idDestino = idDestino; }
    public double getValor() { return valor; }
    public void setValor(double valor) { this.valor = valor; }
}