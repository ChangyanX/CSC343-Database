// CSC343, Introduction to Databases
// Department of Computer Science, University of Toronto

// This code is provided solely for the personal and private use of
// students taking the course CSC343 at the University of Toronto.
// Copying for purposes other than this use is expressly prohibited.
// All forms of distribution of this code, whether as given or with
// any changes, are expressly prohibited.

// Authors: Diane Horton and Marina Tawfik

// Copyright (c) 2020 Diane Horton and Marina Tawfik


import java.sql.*;
import java.util.ArrayList;

public class Assignment2 {

  // A connection to the database
  Connection connection;


  Assignment2() throws SQLException {
    try {
      Class.forName("org.postgresql.Driver");
    } catch  (ClassNotFoundException e) {
      System.out.println("Failed to find the JDBC driver");
      e.printStackTrace();
    }
  }


  /**
   * Connects and sets the search path.
   *
   * Establishes a connection to be used for this session, assigning it to
   * the instance variable 'connection'.  In addition, sets the search
   * path to Library, public.
   *
   * @param  url       the url for the database
   * @param  username  the username to connect to the database
   * @param  password  the password to connect to the database
   * @return           true if connecting is successful, false otherwise
   */
  public boolean connectDB(String url, String username, String password) {
    // Replace the line below and implement this method!
    try{
//            connection = DriverManager.getConnection(url+"?currentSchema=library, public",username,password);
      connection = DriverManager.getConnection(url+"?currentSchema=library, public", username, password);
    }
    catch(SQLException se){
      return false;
    }
    return true;

  }

  /**
   * Closes the database connection.
   *
   * @return true if the closing was successful, false otherwise
   */
  public boolean disconnectDB() {
    try{
      connection.close();
      return true;
    }
    catch(Exception e){
      return false;
    }
  }

  /**
   * Returns the titles of all holdings at the given library branch
   * by any contributor with the given last name.
   * If no matches are found, returns an empty list.
   * If two different holdings happen to have the same title, returns both
   * titles.
   *
   * @param  lastName  the last name to search for.
   * @param  branch    the unique code of the branch to search within.
   * @return           a list containing the titles of the matched items.
   */
  public ArrayList<String> search(String lastName, String branch) {
    // Replace the line below and implement this method!
    try{
      ArrayList<String> titleList = new ArrayList<String>();
      String queryString = "SELECT h.title AS title " +
              "FROM LibraryCatalogue lc " +
              "JOIN holdingContributor hc ON lc.holding = hc.holding " +
              "JOIN Contributor c ON hc.contributor = c.id " +
              "JOIN holding h ON h.id = hc.holding " +
              "WHERE lc.library = ? AND c.last_name = ?; ";
      PreparedStatement searchTitle = connection.prepareStatement(queryString);
      searchTitle.setString(1,branch);
      searchTitle.setString(2,lastName);
      ResultSet rs = searchTitle.executeQuery();

      while (rs.next()){
        String title = rs.getString("title");
        titleList.add(title);
      }
      return titleList;
    }
    catch(SQLException ex){
//      System.out.println("Something goes wrong!");
//      System.err.println("SQL Exception." +
//              "<Message>: " + ex.getMessage());
      return null;
    }

  }


  /**
   * Records a patron's registration for a specific event.
   * Returns True iff
   *  (1) the card number and event ID provided are both valid
   *  (2) This patron is not already registered for this event
   * Otherwise, returns False.
   *
   * @param  cardNumber  card number of the patron.
   * @param  eventID     id of the event.
   * @return             true if the operation was successful
   *                     (as per the above criteria), and false otherwise.
   */
  public boolean register(String cardNumber, int eventID) {
    // Replace the line below and implement this method!
    try {
      // check if cardNumber is valid
      String cardNumQuery = "SELECT EXISTS(SELECT card_number FROM Patron WHERE card_number = ?) " +
              "AS card_number_exists;";
      PreparedStatement cardNum = connection.prepareStatement(cardNumQuery);
      cardNum.setString(1, cardNumber);
      ResultSet rsCardNum = cardNum.executeQuery();
      while (rsCardNum.next()){
        String cardExists = rsCardNum.getString("card_number_exists");
        if (cardExists.equals("f")) return false;
      }

      // check if event ID is valid
      String eventQuery = "SELECT EXISTS(SELECT id FROM libraryEvent WHERE id = ?) AS id_exists;";
      PreparedStatement event = connection.prepareStatement(eventQuery);
      event.setInt(1, eventID);
      ResultSet rsEvent = event.executeQuery();
      while (rsEvent.next()){
        String eventExists = rsEvent.getString("id_exists");
        if (eventExists.equals("f")) return false;
      }


      // check if patron already registered
      String registerQuery = "SELECT EXISTS(SELECT * FROM EventSignUp WHERE patron = ? " +
              "AND event = ?) AS signup_exists;";
      PreparedStatement registration = connection.prepareStatement(registerQuery);
      registration.setString(1, cardNumber);
      registration.setInt(2, eventID);
      ResultSet rsRegistration = registration.executeQuery();
      while (rsRegistration.next()){
        String signUpExists = rsRegistration.getString("signup_exists");
        if (signUpExists.equals("t")) return false; // already registered
      }

      // record registration
      String recordQuery = "INSERT INTO EventSignUp VALUES (?,?);";
      PreparedStatement record = connection.prepareStatement(recordQuery);
      record.setString(1, cardNumber);
      record.setInt(2,eventID);
      record.executeUpdate();
      return true;
    }
    catch(SQLException ex){
//      System.out.println("Something goes wrong!");
//      System.err.println("SQL Exception." +
//              "<Message>: " + ex.getMessage());
      return false;
    }

  }

  /**
   * Records that a checked out library item was returned and returns
   * the fines incurred on that item.
   *
   * Does so by inserting a row in the Return table and updating the
   * LibraryCatalogue table to indicate the revised number of copies
   * available.
   *
   * Uses the same due date rules as the SQL queries.
   * The fines incurred are calculated as follows: for every day overdue
   * i.e. past the due date:
   *    books and audiobooks incurr a $0.50 charge
   *    other holding types incurr a $1.00 charge
   *
   * A return operation is considered successful iff:
   *    (1) The checkout id provided is valid.
   *    (2) A return has not already been recorded for this checkout
   *    (3) The number of available copies is less than the number of holdings
   * If the return operation is unsuccessful, the db instance should not
   * be modified at all.
   *
   * @param  checkout  id of the checkout
   * @return           the amount of fines incurred if the return operation
   *                   was successful, -1 otherwise.
   */
  public double item_return(int checkout) {
    try {
      // Replace the line below and implement this method!
      // when checkout id is not valid
      String checkoutIDQuery = "SELECT EXISTS(SELECT id FROM Checkout WHERE id = ?) AS id_exists;";
      PreparedStatement checkoutID = connection.prepareStatement(checkoutIDQuery);
      checkoutID.setInt(1, checkout);
      ResultSet rsCheckoutNum = checkoutID.executeQuery();

      String checkouExists = new String("");
      while (rsCheckoutNum.next()) {
        checkouExists = rsCheckoutNum.getString("id_exists");
        System.out.println("checkouExists: "+checkouExists);
        if (checkouExists.equals("f")) return -1;
      }


      // when the return has already been recorded
      String inreturnQuery = "SELECT EXISTS(SELECT checkout FROM Return WHERE checkout = ?) AS checkout_exists;";
      PreparedStatement returnExists = connection.prepareStatement(inreturnQuery);
      returnExists.setInt(1, checkout);
      ResultSet rsReturn = returnExists.executeQuery();

      String returnRecordExists = new String("");
      while (rsReturn.next()){
        returnRecordExists = rsReturn.getString("checkout_exists");
        System.out.println("returnRecordExists: "+returnRecordExists);
        if (returnRecordExists.equals("t")) return -1;
      }


      // when the number of available copies is more than or equal to the number of holdings
      String CatalogueQ = "select libraryCatalogue.num_holdings, libraryCatalogue.copies_available from checkout join " +
              "libraryCatalogue using (holding) where checkout.library =libraryCatalogue.library and checkout.id = ?;";
      PreparedStatement catalogue = connection.prepareStatement(CatalogueQ);
      catalogue.setInt(1, checkout);
      ResultSet rsCatalogue = catalogue.executeQuery();

      while (rsCatalogue.next()){
        int num_holdings = rsCatalogue.getInt("num_holdings");
        int copies_available = rsCatalogue.getInt("copies_available");
        System.out.println("compare: " + (copies_available >= num_holdings));
        if (copies_available >= num_holdings) return -1;
      }


      double fine = 0.0;
      int duration = 0;
      double fine_perh = 0.0;
      int due_after = 0;
      String findFine = "select current_date-date(c.checkout_time) as duration, \n" +
              "case when h.htype = 'books' then 0.5\n" +
              "when h.htype = 'audiobooks' then 0.5\n" +
              "else 1 end as fine_perh,\n" +
              "case when h.htype = 'books' then 21\n" +
              "when h.htype = 'audiobooks' then 21\n" +
              "else 7 end as due_after, c.checkout_time\n" +
              "from checkout c join holding h on c.holding = h.id\n" +
              "where c.id = ?;";
      PreparedStatement getFine = connection.prepareStatement(findFine);
      getFine.setInt(1, checkout);
      ResultSet rsFindFine = getFine.executeQuery();

      while (rsFindFine.next()) {
        duration = rsFindFine.getInt("duration");
        fine_perh = rsFindFine.getDouble("fine_perh");
        due_after = rsFindFine.getInt("due_after");
        Timestamp checkout_time = rsFindFine.getTimestamp("checkout_time");
        fine = (duration-due_after)*fine_perh;
        System.out.println("FINE is: "+fine);
      }
      System.out.println("duration is: "+duration);
      System.out.println("fine_perh is: "+fine_perh);
      System.out.println("due_after is: "+due_after);
      System.out.println("FINE is: "+fine);

      // insert into the return table
      String returnQuery = "insert into Return values (?, current_timestamp);";
      PreparedStatement insertReturn = connection.prepareStatement(returnQuery);
      insertReturn.setInt(1, checkout);
      insertReturn.executeUpdate();

      //updating the LibraryCatalogue table
      String updateLib = "update libraryCatalogue set copies_available = copies_available+1 where library " +
              "= (select checkout.library from checkout join libraryCatalogue L1 using (holding) where " +
              " checkout.library = L1.library and checkout.id = ?) and holding =(select checkout.holding " +
              "from checkout join libraryCatalogue L2 using (holding) where checkout.library = L2.library and " +
              "checkout.id =?);";
      PreparedStatement update = connection.prepareStatement(updateLib);
      update.setInt (1, checkout);
      update.setInt(2, checkout);
      update.executeUpdate();

      return fine;

    }catch(SQLException ex){
      System.out.println("Something goes wrong!");
      System.err.println("SQL Exception." +
              "<Message>: " + ex.getMessage());
      return -1;
    }
  }


  public static void main(String[] args) {

    Assignment2 a2;
    try {
      // Demo of using an ArrayList.
//      ArrayList<String> baking = new ArrayList<String>();
//      baking.add("croissant");
//      baking.add("choux pastry");
//      baking.add("jelly roll");

      // Make an instance of the Assignment2 class.  It has an instance
      // variable that will hold on to our database connection as long
      // as the instance exists -- even between method calls.
      a2 = new Assignment2();

      // Use your connect method to connect to your database.  You need
      // to pass in the url, username, and password, rather than have them
      // hard-coded in the method.  (This is different from the JDBC code
      // we worked on in a class exercise.) Replace the XXXXs with your
      // username, of course.
//      a2.connectDB("jdbc:postgresql://localhost:5432/csc343h-yangj295", "yangj295", "");
      a2.connectDB("jdbc:postgresql://localhost:5432/csc343h-xuchangy","xuchangy", "");
      // You can call your methods here to test them. It will not affect our
      // autotester.
//      System.out.println(DriverManager.getConnection("jdbc:postgresql://localhost:5432/csc343h-yangj295",
//              "yangj295", ""));
      System.out.println(DriverManager.getConnection("jdbc:postgresql://localhost:5432/csc343h-xuchangy",
              "xuchangy", ""));
      System.out.println("Boo!");

      /*TEST: Search*/
      ArrayList search_result = a2.search("Margulies","EB");
      System.out.println(search_result);

      /*TEST: Register*/
      boolean register_reuslt = a2.register("1283911752288", 1);
      System.out.println(register_reuslt);
      assert register_reuslt == true;
      register_reuslt = a2.register("13670034122", 2);
      System.out.println(register_reuslt);
      assert register_reuslt == false;

      /*TEST: item_return*/
      double item_return_reuslt = a2.item_return(500);
      System.out.println(item_return_reuslt);
      item_return_reuslt = a2.item_return(1);
      System.out.println(item_return_reuslt);
    }
    catch (Exception ex) {
      System.out.println("exception was thrown");
      ex.printStackTrace();
    }
  }

}


