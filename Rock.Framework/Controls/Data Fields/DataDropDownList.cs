﻿using System;
using System.ComponentModel;
using System.Collections.Generic;
using System.Linq;
using System.Web;
using System.Web.UI;
using System.Web.UI.WebControls;

namespace Rock.Controls
{
    /// <summary>
    /// 
    /// </summary>
    [ToolboxData( "<{0}:DataDropDownList runat=server></{0}:DataDropDownList>" )]
    public class DataDropDownList : LabeledDropDownList
    {
        private Validation.DataAnnotationValidator validator;

        [
        Bindable( true ),
        Category( "Behavior" ),
        DefaultValue( "" ),
        Description( "The model to validate." )
        ]
        public string SourceTypeName
        {
            get
            {
                EnsureChildControls();
                return validator.SourceTypeName;
            }
            set
            {
                EnsureChildControls();
                validator.SourceTypeName = value;
            }
        }

        [
        Bindable( true ),
        Category( "Behavior" ),
        DefaultValue( "" ),
        Description( "The model property that is annotated." )
        ]
        public string PropertyName
        {
            get
            {
                EnsureChildControls();
                return validator.PropertyName;
            }
            set
            {
                EnsureChildControls();
                validator.PropertyName = value;
                if ( this.LabelText == string.Empty )
                    this.LabelText = value.SplitCase();
            }
        }

        protected override void Render( HtmlTextWriter writer )
        {
            base.Render( writer );
            validator.RenderControl( writer );
        }

        protected override void CreateChildControls()
        {
            validator = new Validation.DataAnnotationValidator();
            validator.ID = "dav";
            validator.ControlToValidate = this.ID;
            validator.ForeColor = System.Drawing.Color.Red;

            Controls.Add( validator );

            base.CreateChildControls();
        }
    }
}