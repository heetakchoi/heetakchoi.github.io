import java.math.*;

public class Factorial{
	public static void main(String[] args){
		Factorial f = new Factorial();
		int threadSize = 4;
		if(args != null && args.length > 0){
			threadSize = Integer.parseInt(args[0]);
		}
		f.action(threadSize);
	}

	private void action(int threadSize){
		System.out.println("use thread : "+threadSize);
		long start = System.currentTimeMillis();
		BigInteger[] resultArray = new BigInteger[threadSize];
		SubFactorial[] subFactorialArray = new SubFactorial[threadSize];
		int delta = 100000 / threadSize;
		System.out.println("delta : " +delta);
		for(int i=0; i<threadSize; i++){
			subFactorialArray[i] = new SubFactorial(""+(i*delta + 1), ""+((i+1)*delta), resultArray, i);
		}
		for(SubFactorial subFactorial : subFactorialArray){
			subFactorial.start();
		}
		try{
			for(SubFactorial subFactorial : subFactorialArray){
				subFactorial.join();
			}
		}catch(InterruptedException e){
			e.printStackTrace();
		}

			BigInteger factorial = new BigInteger("1");
		for(BigInteger subFactorial : resultArray){
			factorial = factorial.multiply(subFactorial);
		}
		long end = System.currentTimeMillis();
		System.out.println("bit length : "+factorial.bitLength());
		System.out.println("total time (ms) : "+ (end - start));
	}

	class SubFactorial extends Thread{
		private String from;
		private String to;
		private BigInteger[] resultArray;
		private int resultIndex;
		private SubFactorial(
							 String from, 
							 String to, 
							 BigInteger[] resultArray,
							 int resultIndex){
			this.from = from;
			this.to = to;
			this.resultArray = resultArray;
			this.resultIndex = resultIndex;
		}
		@Override
			public void run(){
			BigInteger factorial = new BigInteger("1");
			BigInteger n = new BigInteger(to);
			BigInteger k = new BigInteger(from);
			BigInteger one = new BigInteger("1");
			while(k.compareTo(n)<= 0){
				factorial = factorial.multiply(k);
				k = k.add(one);
			}
			resultArray[resultIndex] = factorial;
			System.out.println(from+" - "+to+" end");
		}
	}
}