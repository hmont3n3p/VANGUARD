import { LightningElement,track,wire,api } from 'lwc';
import getEvents from '@salesforce/apex/EventController.getSyncEventMessage';
import {
  FlowNavigationBackEvent,
  FlowNavigationNextEvent
} from "lightning/flowSupport";
export default class CitasDisponibles extends LightningElement {
    @api fechaCita; 
    @api centroId; 
    @api especialistaId;
    @api event;
    @api availableActions = [];

    @track startDate=new Date();
    @track endDate;
    error;
    openModal = false;
    events=[];
    @wire(getEvents,{DateAppointment:'$fechaCita',Center:'$centroId',WhoId:'$especialistaId'})
      eventObj(value){
          const {data, error} = value;
          if(data){
              //format as fullcalendar event object
              let records = data.map(event => {
                  return { Id : event.Id, 
                          title : new Date(event.StartDateTime).toLocaleTimeString() +' - ' + new Date(event.EndDateTime).toLocaleTimeString(), 
                          start : event.StartDateTime,
                          end : event.EndDateTime,
                          allDay : event.IsAllDayEvent};
              });
              this.events = JSON.parse(JSON.stringify(records));
              this.error = undefined;
          }else if(error){
              this.events = [];
              this.error = 'No events are found';
          }
     }
      handleEvent(event) { 
        var tmp=[...this.events]; 
        let task = tmp.find(x=>x.title=event.target.label); 
        this.startDate=task.start;
        this.title=task.title;
        this.endDate=task.end;
        this.event=  JSON.stringify(task);       
        this.handleNext();
      }
      handleCancel(event) {
        this.openModal = false;
      }

      addHours(date, hours) {
        date.setHours(date.getHours() + hours);
        return date;
      }
      handleNext() {
        if (this.availableActions.find((action) => action === "NEXT")) {
          const navigateNextEvent = new FlowNavigationNextEvent();
          this.dispatchEvent(navigateNextEvent);
        }
      } 
}