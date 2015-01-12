import java.awt.Robot;
import java.awt.AWTException;
/**
  a simple program that moves the mouse on a machine to stop the screen saver
	implements java.awt.Robot
  @author Jason Wolanyk
	@version 07122012	
*/
public class MouseJiggle
{
	/**
		makes the robot and moves the mouse
		@param void
	*/
	public static void main(String[] args)
	{
		try
		{
			System.out.printf("moving");
			//create a robot and have it move the mouse
			Robot x = new Robot();
			for (int i = 0; i<10; i++)
			{
				System.out.printf(".");
				x.mouseMove(i*10,i*10);
				x.delay(100);
			}
			x.mouseMove(0,0);
			System.out.printf("Done\n");
		}
		catch (AWTException e)
		{
			e.printStackTrace();
			System.out.println("Message = "+e.getMessage()+"\n");
			System.out.println("AWTException ocured");
			System.out.println("Either the node is headless, meaning this program is useless");
			System.out.println("Or the system is blocking access to low level input ctrl");
		}
		catch (SecurityException e)
	  {		
 		  e.printStackTrace();
			System.out.println("Message = "+e.getMessage()+"\n");
			System.out.println("Security exception occored read the jibberish");
		}
		catch (Exception e)
		{		
			e.printStackTrace();
			System.out.println("Message = "+e.getMessage()+"\n");
			System.out.println("Something blewup, I don't know what. FIX IT");
		}
	}//end of main()
}//end of class
