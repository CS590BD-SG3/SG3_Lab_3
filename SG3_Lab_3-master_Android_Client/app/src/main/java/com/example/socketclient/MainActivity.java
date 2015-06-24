package com.example.socketclient;

import android.app.Activity;
import android.content.ActivityNotFoundException;
import android.content.Intent;
import android.os.AsyncTask;
import android.os.Bundle;
import android.speech.RecognizerIntent;
import android.util.Log;
import android.view.View;
import android.view.View.OnClickListener;
import android.widget.Button;
import android.widget.EditText;
import android.widget.TextView;
import android.widget.Toast;

import java.io.IOException;
import java.io.OutputStream;
import java.io.PrintStream;
import java.net.Socket;
import java.net.UnknownHostException;
import java.util.ArrayList;

public class MainActivity extends Activity {
 TextView textResponse;
 EditText editTextAddress, editTextPort, editTextCommand;
 Button buttonConnect,buttonClear,buttonSendCommand,buttonStop, buttonSpeak;
 String command;
 Boolean checkupdate=false;
 protected static final int RESULT_SPEECH = 1;

 @Override
 protected void onCreate(Bundle savedInstanceState) {
  super.onCreate(savedInstanceState);
  setContentView(R.layout.activity_main);
  
  editTextAddress = (EditText)findViewById(R.id.address);
  editTextPort = (EditText)findViewById(R.id.port);
  editTextCommand = (EditText)findViewById(R.id.command);
  buttonConnect = (Button)findViewById(R.id.connect);
  buttonClear = (Button)findViewById(R.id.clear);
  buttonSendCommand = (Button)findViewById(R.id.sendCommand);
  buttonSpeak = (Button)findViewById(R.id.speakBtn);
  textResponse = (TextView)findViewById(R.id.response);


     buttonSpeak.setOnClickListener(new View.OnClickListener() {
         @Override
         public void onClick(View v) {

             Intent intent = new Intent(RecognizerIntent.ACTION_RECOGNIZE_SPEECH);
             intent.putExtra(RecognizerIntent.EXTRA_LANGUAGE_MODEL,
                     RecognizerIntent.LANGUAGE_MODEL_FREE_FORM);

             try {
                 startActivityForResult(intent, RESULT_SPEECH);
                 editTextCommand.setText("");
             } catch (ActivityNotFoundException a) {
                 Toast t = Toast.makeText(getApplicationContext(),
                         "Your device doesn't support Speech to Text",
                         Toast.LENGTH_SHORT);
                 t.show();
             }
         }
     });

  buttonStop=(Button) findViewById(R.id.stop);
  buttonStop.setOnClickListener(new OnClickListener(){

		@Override
		public void onClick(View arg0) {
			// TODO Auto-generated method stub
			command="stop";
			checkupdate=true;
		}
		  
	  });

  buttonConnect.setOnClickListener(buttonConnectOnClickListener);

  buttonClear.setOnClickListener(new OnClickListener(){

   @Override
   public void onClick(View v) {
    textResponse.setText("");
    editTextCommand.setText("");
   }});

  buttonSendCommand.setOnClickListener(buttonSendCommandOnClickListener);
 }

    @Override
    protected void onActivityResult(int requestCode, int resultCode, Intent data)
    {
        if (requestCode == RESULT_SPEECH && resultCode == RESULT_OK) {
            ArrayList<String> results = data.getStringArrayListExtra(
                    RecognizerIntent.EXTRA_RESULTS);
            editTextCommand.setText(results.get(0));
        }
        super.onActivityResult(requestCode, resultCode, data);
    }
 OnClickListener buttonConnectOnClickListener =
			new OnClickListener(){

				@Override
				public void onClick(View arg0) {
					MyClientTask myClientTask = new MyClientTask(
							editTextAddress.getText().toString(),
							Integer.parseInt(editTextPort.getText().toString()));
					myClientTask.execute();
				}};

OnClickListener buttonSendCommandOnClickListener =
		new OnClickListener(){

			@Override
			public void onClick(View arg0) {
				command = editTextCommand.getText().toString();
				checkupdate=true;
			}};

    public class MyClientTask extends AsyncTask<Void, Void, Void> {
  
  String dstAddress;
  int dstPort;
  String response = "";
  
  MyClientTask(String addr, int port){
   dstAddress = addr;
   dstPort = port;
  }
  @Override
	protected Void doInBackground(Void... arg0) {

		OutputStream outputStream;
		Socket socket = null;

		try {
			socket = new Socket(dstAddress, dstPort);
			Log.d("MyClient Task", "Destination Address : " + dstAddress);
			Log.d("MyClient Task", "Destination Port : " + dstPort + "");
			outputStream = socket.getOutputStream();
			PrintStream printStream = new PrintStream(outputStream);
			
			while (true) {
				if(checkupdate)
				{
					Log.d("Command", command);
					Log.d("checkUpdate", checkupdate.toString());
					printStream.print(command);
					printStream.flush();
					Log.d("Socket connection", socket.isClosed()+"");
					checkupdate=false;
				}
			}

		} catch (UnknownHostException e) {
			// TODO Auto-generated catch block
			e.printStackTrace();
			response = "UnknownHostException: " + e.toString();
		} catch (IOException e) {
			// TODO Auto-generated catch block
			e.printStackTrace();
			response = "IOException: " + e.toString();
		} finally {
			if (socket != null) {
				try {
					socket.close();
				} catch (IOException e) {
					// TODO Auto-generated catch block
					e.printStackTrace();
				}
			}
		}
		return null;
	}

  @Override
  protected void onPostExecute(Void result) {
      textResponse.setText(response);
      super.onPostExecute(result);
  }
 }

}
