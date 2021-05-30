import _ from 'lodash';
import React from 'react';
import { View, Text, ScrollView } from 'react-native';
import ReactDataSheet from 'react-datasheet';
import { v4 as uuidv4 } from 'uuid';
import { EJSON } from 'bson';

import Button from '../../components/Button';
import JsonCode from './JsonCode';

class ValueViewer extends React.PureComponent {

  render() {
    
    const { value } = this.props.value;
    
    if (_.isString(value)) {
      return <Text>{value}</Text>;
    }
    
    return <Text>{EJSON.stringify(value)}</Text>;
  }
}

class DataSheet extends React.PureComponent {

  constructor(props) {
    super(props);

    this.state = {
      token: uuidv4(),
    };
  }

  render() {
    return <ReactDataSheet
      data={this.props.data}
      sheetRenderer={props => <table className={props.className}>
            <thead style={{
              backgroundColor: 'white',
              position: 'sticky',
              top: 0,
            }}>
                <tr>
                  <th />
                  {this.props.columns.map((col, i) => <th key={`${this.state.token}-col-${i}`}>
                    <Text>{col}</Text>
                    </th>)}
                </tr>
            </thead>
            <tbody style={{
              backgroundColor: 'white',
            }}>
                {props.children}
            </tbody>
        </table>}
      rowRenderer={props => (
        <tr>
            <td><Text>{props.row}</Text></td>
            {props.children}
        </tr>
      )}
      valueViewer={ValueViewer}
      valueRenderer={x => x} />;
  }
}

export default class ResultTable extends React.PureComponent {

  constructor(props) {
    super(props);

    this.state = {
      token: uuidv4(),
      style: 'table',
    };
  }

  renderBody() {
    
    if (!_.isArray(this.props.data)) {
      return <JsonCode value={this.props.data} space={4} />;
    }

    switch (this.state.style) {

      case 'table':

        const columns = this.props.data.reduce((result, x) => _.uniq(result.concat(Object.keys(x))), []);
        const grid = this.props.data.map(x => columns.map(c => { return { value: x[c] } }));

        return <ScrollView style={{ flex: 1 }}>
          <DataSheet
          data={grid}
          columns={columns} />
        </ScrollView>;

      case 'raw':
        return <ScrollView style={{ flex: 1 }}>
        <JsonCode value={this.props.data} space={4} />
        </ScrollView>
    }
  }

  render() {
    
    const { 
      data, 
      ...props
    } = this.props;
    
    return <View {...props}>
    <View style={{ flexDirection: 'row' }}>
      {_.isArray(this.props.data) && <Button title='table' onPress={() => this.setState({ style: 'table' })} />}
      <Button title='raw' onPress={() => this.setState({ style: 'raw' })} />
    </View>
    {this.renderBody()}
    </View>;
  }
}