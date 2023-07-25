import { LightningElement, track, wire, api } from 'lwc';
import getContact from '@salesforce/apex/EventController.getContact';
import getCentro from '@salesforce/apex/EventController.getCentro';
import createNewCita from '@salesforce/apex/EventController.buildMedAptment';
import LightningConfirm from 'lightning/confirm';
import LightningAlert from 'lightning/alert';
import {
  FlowNavigationBackEvent,
  FlowNavigationNextEvent,
  FlowNavigationFinishEvent 
} from "lightning/flowSupport";
export default class ResumenCita extends LightningElement {
  @api fechaCita;
  @api centroId;
  @api especialistaId;
  @api event;

  @api nombre;
  @api apellido;
  @api email;
  @api movil;
  @api observaciones;
  @api availableActions = [];


  error;
  openModal = false;

  @track especialista;
  @track centro;


  @wire(getCentro, { IdCentro: '$centroId' })
  searchCentro(value) {
    const { data, error } = value;
    if (data) {
      let centros = data.map(centro => {
        return {
          Id: centro.Id,
          Name: centro.Name,
          RealName: centro.VAN_Name__c,
          IsActive: centro.VAN_IsActive__c
        };
      });

      this.centro = JSON.parse(JSON.stringify(centros[0]));
      this.error = undefined;
    } else if (error) {
      this.error = 'No centros are found';
    }
  }
  @wire(getContact, { IdContact: '$especialistaId' })
  searchEspecialista(value) {
    const { data, error } = value;
    if (data) {
      let especialistas = data.map(person => {
        return {
          Id: person.Id,
          Name: person.Name,
          Title: person.Title,
          Phone: person.Phone,
          Email: person.Email
        };
      });
      this.especialista = JSON.parse(JSON.stringify(especialistas[0]));
      console.log(especialista);
      this.error = undefined;
    } else if (error) {
      this.error = 'No especialistas found';
    }
  }
  get doctorURL() {
    return '/lightning/r/Contact/' + this.especialistaId + '/view';
  }
  connectedCallback() {
    this.event = JSON.parse(this.event);
  }
  createNewCita(){
    createNewRecord({})
        .then(result => {
            if(result){
                console.log(result);
            }
        })
        .catch(error => {
            console.log('Error: ', error);
        })
}
  handleEvent() {
    const fechaCita = this.event.start;
    const nombreCliente = this.nombre;
    const apellidoCliente = this.apellido;
    const email = this.email;
    const movil = this.movil;
    const observaciones = this.observaciones;
    const IdEspecialista = this.especialistaId;
    const IdCentro = this.centroId;
      createNewCita({
        fechaCita: fechaCita,
        nombreCliente: nombreCliente,
        apellidoCliente: apellidoCliente,
        email: email,
        movil: movil,
        observaciones: observaciones,
        IdEspecialista: IdEspecialista,
        IdCentro: IdCentro,
      })
        .then((result) => {
          console.log(JSON.stringify(result));
          this.handleConfirmClick();
        })
        .catch((error) => {
          console.log(error);
        });
  }
  async handleConfirmClick() {
    const result = await LightningAlert.open({
        message: 'Cita Creada Correctamente',
        variant: 'header',
        label: '',
        theme:'green'
    });
    this.handleFinish();
  }
  handleFinish() {
    if (this.availableActions.find((action) => action === "FINISH")) {
      const flowNavigationFinishEvent  = new FlowNavigationFinishEvent ();
      this.dispatchEvent(flowNavigationFinishEvent);
    }
  } 

}