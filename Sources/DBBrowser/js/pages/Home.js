import _ from 'lodash';
import React from 'react';
import { Button, View, TextInput, Text, ScrollView } from 'react-native';
import { withRouter } from "react-router";
import { EJSON } from 'bson';

import { withDatabase } from '../utils/database';

class Home extends React.Component {

  constructor(props) {
    super(props);

    this.state = {
      isConnected: false,
      connectionStr: '',
      command: '',
      result: '',
    };
  }

  async connect() {
    
    try {

      const database = this.props.database;
  
      await database.connect(this.state.connectionStr);

      this.setState({ isConnected: true });

    } catch (e) {
      console.log(e);
    }
  }

  async runCommand() {

    try {

      const database = this.props.database;

      let result;
  
      if (this.state.connectionStr.startsWith('mongodb://')) {
        
        const command = EJSON.parse(this.state.command);

        result = await database.runMongoCommand(command);

      } else {

        result = await database.runSQLCommand(this.state.command);
      }

      this.setState({ result: EJSON.stringify(result, null, 4) });
      
    } catch (e) {
      console.log(e);
    }
  }

  render_query_page() {
    
    return (
      <View style={{ flex: 1, padding: 10 }}>
        <TextInput
        multiline
        onChangeText={(command) => this.setState({ command })}
        value={this.state.command} />
        <Button title='Run' onPress={() => this.runCommand()} />
        <ScrollView style={{ flex: 1 }}>
        <Text>{this.state.result}</Text>
        </ScrollView>
      </View>
    );
  }
  
  render_login_page() {

    return (
      <View style={{ flex: 1, padding: 10 }}>
        <TextInput
        onChangeText={(connectionStr) => this.setState({ connectionStr })}
        value={this.state.connectionStr} />
        <Button title='Connect' onPress={() => this.connect()} />
      </View>
    );
  }
  
  render() {
    return this.state.isConnected ? this.render_query_page() : this.render_login_page();
  }
}

export default withRouter(withDatabase(Home));