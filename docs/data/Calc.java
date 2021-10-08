import java.lang.Math;

public class Calc{
    public static void main(String[] args){
	double a = 1.0;
	double b = 1.0;
	double c = 1.0;
	double d = 1.0;
	int unitCnt = 100;

	double leftT = (d-b)/a;
	double rightT = (d+b)/a;
	double unitSize = (2*b/a)/unitCnt;
	double[] tArray = new double[unitCnt+1];
	for(int i=0; i<=unitCnt; i++){
	    tArray[i] = leftT + i*unitSize;
	}
	System.out.printf("a %f b %f c %f d %f \n", a, b, c, d);
	for(int i=0; i<=unitCnt; i++){
	    double t = tArray[i];
	    System.out.printf(" F(%f)= %f\n", t, getY(a, b, c, d, t));
	}
    }
    private static double getY(double a, double b, double c, double d, double t){
	return (a * t + b * Math.sin(c*t) - d);
    }
}